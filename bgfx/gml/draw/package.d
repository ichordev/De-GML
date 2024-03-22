module gml.draw;

public import
	gml.draw.forms,
	gml.draw.gpu,
	gml.draw.texture;

import gml.camera, gml.collision, gml.colour, gml.display, gml.game, gml.input.mouse, gml.options, gml.room, gml.window;

import core.time, core.thread;
import std.algorithm.comparison, std.exception, std.format, std.math, std.string;
import ic.vec;
static import shelper;
import bindbc.sdl, bindbc.bgfx;

void init(){
	masterViewportPos1 = Vec2!ushort(0, 0);
	masterViewportPos2 = Vec2!ushort(windowSize.x, windowSize.y);
	masterViewportScale = Vec2!double(1.0, 1.0);
	
	SDL_SysWMinfo wmi;
	SDL_GetVersion(&wmi.version_);
	enforce(SDL_GetWindowWMInfo(window, &wmi), "SDL failed to get window WM info: %s".format(SDL_GetError().fromStringz()));
	
	auto bgfxInit = bgfx.Init(0);
	
	bgfxInit.resolution.width  = windowSize.x;
	bgfxInit.resolution.height = windowSize.y;
	bgfxInit.resolution.reset  = bgfxResetFlags;
	
	switch(wmi.subsystem){
		version(linux){
			case SDL_SYSWM_X11:
				bgfxInit.platformData.nwh = cast(void*)wmi.info.x11.window;
				bgfxInit.platformData.ndt = wmi.info.x11.display;
				bgfxInit.type = RendererType.vulkan;
				break;
			case SDL_SYSWM_WAYLAND:
				bgfxInit.platformData.nwh = SDL_GetWindowData(window, "wl_egl_window");
				bgfxInit.platformData.ndt = wmi.info.wl.display;
				bgfxInit.type = RendererType.vulkan;
				break;
		}
		version(OSX){
			case SDL_SYSWM_COCOA:
				SDL_MetalView view = SDL_Metal_CreateView(window);
				bgfxInit.platformData.nwh = SDL_Metal_GetLayer(view);
				bgfxInit.type = RendererType.metal;
				break;
		}
		version(iOS){
			case SDL_SYSWM_UIKIT:
				bgfxInit.platformData.nwh = wmi.info.uikit.window;
				bgfxInit.type = RendererType.metal;
				break;
		}
		version(Android){
			case SDL_SYSWM_ANDROID:
				bgfxInit.platformData.nwh = wmi.info.android.window;
				bgfxInit.type = RendererType.vulkan;
				break;
		}
		version(Windows){
			case SDL_SYSWM_WINDOWS:
				bgfxInit.platformData.nwh = wmi.info.win.window;
				bgfxInit.type = RendererType.direct3D11;
				break;
		}
		default:
			enforce(0, "Your windowing sub-system is not supported on this platform.");
	}
	enforce(bgfx.init(bgfxInit), "bgfx failed to initialise");
	
	u_colour = bgfx.createUniform("u_colour", UniformType.vec4, 1);
	shPassPos       = shelper.load("passPos",       "uniformCol");
	shPassPosCol    = shelper.load("passPosCol",    "passCol");
	
	prevFrameTime = MonoTime.zero();
	gpuState = GPUState.init;
	gpuState.col[] = options.defaultDrawColour[];
	gpuState.program = shPassPos;
	
	VertPos.init();
	VertPosCol.init();
	VertPosColTex.init();
	
	gml.draw.forms.init();
	gml.draw.gpu.init();
	gml.draw.texture.init();
}

void quit(){
	gml.draw.texture.quit();
	gml.draw.gpu.quit();
	gml.draw.forms.quit();
	
	shelper.unloadAllShaderPrograms();
	bgfx.destroy(u_colour);
	
	bgfx.shutdown();
}

bgfx.ProgramHandle shPassPos, shPassPosCol;
bgfx.UniformHandle u_colour;

MonoTime prevFrameTime;

void startFrame(){
	if(prevFrameTime == MonoTime.zero()){
		prevFrameTime = MonoTime.currTime;
	}
	
	if(windowSize != prevWindowSize){
		bgfx.reset(windowSize.x, windowSize.y, bgfxResetFlags);
		
		const roomWindowSize = roomData.windowSize;
		if(options.keepAspectRatio){
			const ratio = roomWindowSize.x / cast(double)roomWindowSize.y;
			const masterViewportSize = {
				if(cast(uint)(windowSize.x / ratio) > windowSize.y){
					return Vec2!ushort(
						cast(ushort)ceil(windowSize.y * ratio),
						cast(ushort)windowSize.y,
					);
				}else{
					return Vec2!ushort(
						cast(ushort)windowSize.x,
						cast(ushort)ceil(windowSize.x / ratio),
					);
				}
			}();
			masterViewportPos1 = Vec2!ushort(
				cast(ushort)(windowSize.x / 2),
				cast(ushort)(windowSize.y / 2),
			) - (masterViewportSize / 2);
			masterViewportPos2 = masterViewportPos1 + masterViewportSize;
			masterViewportScale = Vec2!double(masterViewportSize.x / cast(double)roomWindowSize.x);
		}else{
			masterViewportPos1 = Vec2!ushort(0, 0);
			masterViewportPos2 = Vec2!ushort(windowSize.x, windowSize.y);
			masterViewportScale = cast(Vec2!double)(masterViewportPos2 - masterViewportPos1) / Vec2!double(
				roomWindowSize.x, roomWindowSize.y,
			);
		}
	}
	
	if(roomData.useViews){
		foreach(viewport; roomData.viewports){
			if(viewport.visible){
				if(viewport.camera){
					viewport.camera.update();
				}
			}
		}
	}
	
	viewCurrent = 0;
	viewNext = 0;
	gpuState.bgfxView = 0;
	gpuState.bgfxViewNext = 1;
	
	bgfx.setViewClear(gpuState.bgfxView, Clear.colour | Clear.depth, windowColour);
	bgfx.setViewRect(gpuState.bgfxView, 0, 0, cast(ushort)windowSize.x, cast(ushort)windowSize.y);
	bgfx.touch(gpuState.bgfxView);
}

bool nextView(){
	viewCurrent = viewNext;
	
	if(roomData.useViews){
		if(viewCurrent > 0){
			if(viewportCam){
				viewportCam.end();
			}
		}
		
		//find first visible viewport
		Viewport port;
		while(viewCurrent < 8){
			port = roomData.viewports[viewCurrent];
			if(port.visible){
				break;
			}
			viewCurrent++;
		}
		if(viewCurrent >= 8) return false;
		
		port.apply();
		
		viewNext = viewCurrent+1;
	}else{
		if(viewCurrent >= 1) return false;
		
		const roomWindowSize = roomData.windowSize;
		viewportPos = Vec2!ushort(0, 0);
		viewportSize = Vec2!ushort(roomWindowSize.x, roomWindowSize.y);
		
		viewportCam = null;
		
		viewNext = 1;
	}
	
	if(viewportCam){
		viewMat = viewportCam.view;
		projMat = viewportCam.proj;
	}else{
		viewMat = Camera.getDefaultView();
		projMat = Camera.getDefaultProj(bgfx.getCaps().homogeneousDepth);
	}
	scaleToMasterViewport(viewportPos, viewportSize);
	
	gpuState.nextBgfxView();
	return true;
}

void endFrame(){
	bgfx.frame();
	viewportCam = null;
	
	auto now = MonoTime.currTime;
	Duration waitFor = (prevFrameTime + frameDelay) - now;
	
	while(waitFor > usecs(50)){
		Thread.sleep(waitFor - usecs(50));
		
		now = MonoTime.currTime;
		waitFor = (prevFrameTime + frameDelay) - now;
	}
	const addNewPrevFrameTime = prevFrameTime + frameDelay;
	const nowNewPrevFrameTime = MonoTime.currTime;
	prevFrameTime = addNewPrevFrameTime.ticks > nowNewPrevFrameTime.ticks ? addNewPrevFrameTime : nowNewPrevFrameTime;
}

struct GPUState{
	float[4] col = [1f, 1f, 1f, 1f];
	@property uint intCol() nothrow @nogc pure @safe =>
		cast(uint)round(col[0] * 255f) <<  0 |
		cast(uint)round(col[1] * 255f) <<  8 |
		cast(uint)round(col[2] * 255f) << 16 |
		cast(uint)round(col[3] * 255f) << 24;
	
	Mat4 getTransform() nothrow @nogc @safe =>
		worldMat.translate(Vec3!float(0f, 0f, depth));
	
	float depth = 0f;
	
	bool zTest = false;
	bool alphaTest = false;
	
	auto getBgfxState() nothrow @nogc pure @safe =>
		write | blendMode | culling
		| (zTest ? zFunc : 0)
		| (alphaTest ? alphaRef : 0);
	
	bgfx.StateWrite_ write = StateWrite.rgb | StateWrite.a | StateWrite.z;
	
	bgfx.StateBlend_ blendMode = BM.normal;
	
	bgfx.StateCull_ culling = 0;
	
	bgfx.StateDepthTest_ zFunc = StateDepthTest.lEqual;
	bgfx.StateAlphaRef_ alphaRef = (() @trusted => toStateAlphaRef(0))();
	
	bgfx.ViewID bgfxViewNext = 0;
	bgfx.ViewID bgfxView = 0;
	
	void nextBgfxView() nothrow @nogc{
		bgfxView = bgfxViewNext;
		bgfxViewNext++;
		setUpBgfxView();
	}
	
	void setUpBgfxView() nothrow @nogc{
		bgfx.setViewRect(
			bgfxView,
			viewportPos.x,
			viewportPos.y,
			viewportSize.x,
			viewportSize.y,
		);
		bgfx.setViewTransform(bgfxView, &viewMat, &projMat);
		bgfx.touch(bgfxView);
	}
	
	bgfx.ProgramHandle program;
}
GPUState gpuState;

struct VertPos{
	float x,y;
	
	static bgfx.VertexLayout layout;
	static void init() nothrow @nogc{
		layout.begin()
			.add(Attrib.position,  2, AttribType.float_)
		.end();
	}
}
struct VertPosCol{
	float x,y;
	uint col;
	
	static bgfx.VertexLayout layout;
	static void init() nothrow @nogc{
		layout.begin()
			.add(Attrib.position,  2, AttribType.float_)
			.add(Attrib.colour0,   4, AttribType.uint8, true)
		.end();
	}
}
struct VertPosColTex{
	float x,y;
	uint col;
	float u,v;
	
	static bgfx.VertexLayout layout;
	static void init() nothrow @nogc{
		layout.begin()
			.add(Attrib.position,  2, AttribType.float_)
			.add(Attrib.colour0,   4, AttribType.uint8, true)
			.add(Attrib.texCoord0, 2, AttribType.float_)
		.end();
	}
}

uint drawGetColour() nothrow @nogc @safe =>
	(cast(ubyte)round(gpuState.col[0] * 255f) <<  0) |
	(cast(ubyte)round(gpuState.col[1] * 255f) <<  8) |
	(cast(ubyte)round(gpuState.col[2] * 255f) << 16);
alias draw_get_colour = drawGetColour;

float drawGetAlpha() nothrow @nogc @safe =>
	gpuState.col[3];

void drawClear(uint col) nothrow @nogc{
	gpuState.nextBgfxView();
	bgfx.setViewClear(gpuState.bgfxView, Clear.colour | Clear.depth, (.col(col) << 8) | 0xFF);
}
alias draw_clear = drawClear;

void drawClearAlpha(uint col, float alpha) nothrow @nogc{
	gpuState.nextBgfxView();
	bgfx.setViewClear(gpuState.bgfxView, Clear.colour | Clear.depth, (.col(col) << 8) | cast(ubyte)round(alpha * 255f));
}
alias draw_clear_alpha = drawClearAlpha;

void drawSetAlpha(float alpha) nothrow @nogc @safe{
	gpuState.col[3] = clamp(alpha, 0f, 1f);
}
alias draw_set_alpha = drawSetAlpha;

void drawSetColour(uint col) nothrow @nogc @safe{
	gpuState.col[0] = ((col >>  0) & 0xFF) / 255f;
	gpuState.col[1] = ((col >>  8) & 0xFF) / 255f;
	gpuState.col[2] = ((col >> 16) & 0xFF) / 255f;
}
alias draw_set_colour = drawSetColour;

Mat4 matrixBuildProjectionOrtho(float w, float h, float zNear, float zFar) nothrow @nogc =>
	Mat4.projOrtho(Vec2!float(0f, 0f), Vec2!float(w, h), zNear, zFar, bgfx.getCaps().homogeneousDepth);
alias matrix_build_projection_ortho = matrixBuildProjectionOrtho;

Mat4 matrixBuildProjectionOrtho(float x, float y, float w, float h, float zNear, float zFar) nothrow @nogc =>
	Mat4.projOrtho(Vec2!float(x, y), Vec2!float(x+w, y+h), zNear, zFar, bgfx.getCaps().homogeneousDepth);

Mat4 matrixBuildProjectionPerspective(float w, float h, float zNear, float zFar) nothrow @nogc =>
	Mat4.projPersp(Vec2!float(0f, 0f), Vec2!float(w, h), zNear, zFar, bgfx.getCaps().homogeneousDepth);
alias matrix_build_projection_perspective = matrixBuildProjectionPerspective;

Mat4 matrixBuildProjectionPerspectiveFov(float fov, float aspect, float zNear, float zFar) nothrow @nogc =>
	Mat4.projPersp(fov, aspect, zNear, zFar, bgfx.getCaps().homogeneousDepth);
alias matrix_build_projection_perspective_fov = matrixBuildProjectionPerspectiveFov;

Vec2!int reverseEngineerMousePos(Viewport port, Vec2!ushort portPos, Vec2!ushort portSize) nothrow @nogc @safe{
	Mat4 view, proj;
	
	bool homoNDC = (() @trusted => bgfx.getCaps().homogeneousDepth)();
	if(port.camera){
		view = port.camera.view;
		proj = port.camera.proj;
	}else{
		view = Camera.getDefaultView();
		proj = Camera.getDefaultProj(homoNDC);
	}
	
	Vec2!double pos;
	if(homoNDC){
		pos = cast(Vec2!double)(absMousePos - cast(Vec2!int)(portPos)) / cast(Vec2!double)portSize;
	}else{
		pos = cast(Vec2!double)(absMousePos - cast(Vec2!int)(portPos + (portSize / 2))) / cast(Vec2!double)(portSize / 2);
	}
	pos.y = -pos.y;
	pos = (proj * view).invert() * pos;
	
	return cast(Vec2!int)pos;
}

Vec2!int getViewsMousePos() nothrow @nogc @safe{
	if(roomData.useViews){
		Vec2!ushort portPos, portSize;
		
		foreach(port; roomData.viewports){
			portPos = port.pos;
			portSize = port.size;
			scaleToMasterViewport(portPos, portSize);
			
			if(port.visible && pointInRectangle(absMousePos.x, absMousePos.y, portPos.x, portPos.y, portPos.x+portSize.x, portPos.y+portSize.y)){
				return reverseEngineerMousePos(port, portPos, portSize);
			}
		}
		foreach(port; roomData.viewports){
			if(port.visible){
				portPos = port.pos;
				portSize = port.size;
				scaleToMasterViewport(portPos, portSize);
				return reverseEngineerMousePos(port, portPos, portSize);
			}
		}
	}
	return absMousePos;
}

@property int mouseX() nothrow @nogc @safe{
	if(mouseViewPosDirty){
		mouseViewPos = getViewsMousePos();
	}
	return mouseViewPos.x;
}
alias mouse_x = mouseX;

@property int mouseY() nothrow @nogc @safe{
	if(mouseViewPosDirty){
		mouseViewPos = getViewsMousePos();
	}
	return mouseViewPos.y;
}
alias mouse_y = mouseY;

int windowViewMouseGetX(uint id) nothrow @nogc @safe{
	if(mouseViewsPosDirty[id]){
		auto portPos  = roomData.viewports[id].pos;
		auto portSize = roomData.viewports[id].size;
		scaleToMasterViewport(portPos, portSize);
		mouseViewsPos[id] = reverseEngineerMousePos(roomData.viewports[id], portPos, portSize);
	}
	return mouseViewsPos[id].x;
}
alias window_view_mouse_get_x = windowViewMouseGetX;

int windowViewMouseGetY(uint id) nothrow @nogc @safe{
	if(mouseViewsPosDirty[id]){
		auto portPos  = roomData.viewports[id].pos;
		auto portSize = roomData.viewports[id].size;
		scaleToMasterViewport(portPos, portSize);
		mouseViewsPos[id] = reverseEngineerMousePos(roomData.viewports[id], portPos, portSize);
	}
	return mouseViewsPos[id].y;
}
alias window_view_mouse_get_y = windowViewMouseGetY;

alias windowViewsMouseGetX = mouseX;
alias window_views_mouse_get_x = windowViewsMouseGetX;

alias windowViewsMouseGetY = mouseY;
alias window_views_mouse_get_y = windowViewsMouseGetY;

void cameraApply(Camera cameraID) nothrow @nogc{
	viewportCam = cameraID;
	gpuState.nextBgfxView();
}
alias camera_apply = cameraApply;
