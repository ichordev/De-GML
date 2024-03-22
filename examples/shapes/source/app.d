module app;

import std.file, std.math, std.path;
import ic.calc, ic.vec;
import shelper;
import gml;

void main(){
	shelper.shaderPath = buildNormalizedPath(thisExePath()~"/../../shaders/")~"/";
	
	options.allowWindowResize = true;
	options.keepAspectRatio = true;
	
	auto myCam1 = cameraCreate();
	cameraSetProjMat(myCam1, matrixBuildProjectionOrtho(100, 350, -16000f, 16000f));
	auto myCam2 = cameraCreate();
	cameraSetProjMat(myCam2, matrixBuildProjectionOrtho(50, 50, 700, 500, -16000f, 16000f));
	
	gml.room.orderedRooms ~= Room(
		size: Vec2!uint(800, 600),
		useViews: true,
		viewports: [
			Viewport(
				visible: true,
				pos: Vec2!ushort(50, 50),
				size: Vec2!ushort(300, 500),
				camera: myCam1,
			),
			Viewport(
				visible: true,
				pos: Vec2!ushort(400, 250),
				size: Vec2!ushort(100, 200),
				camera: myCam2,
			),
			Viewport(), 
			Viewport(
				visible: true,
				pos: Vec2!ushort(360, 75),
				size: Vec2!ushort(80, 60),
			),
			Viewport(), Viewport(),
			Viewport(), Viewport(),
		],
	);
	gml.initAll();
	
	windowSetColour(col(0x4F_AF_FF));
	
	float s = 0f;
	while(processEvents()){
		s += 0.04f;
		s %= pi*2f;
		float x = sin(s)*0.5f + 0.5f;
		float y = abs(cos(s));
		
		startFrame();
		while(nextView()){
			drawClear(C.grey);
			drawSetColour(0xFF_FF_FF);
			drawCircle(mouseX, mouseY, 5, false);
			drawRectangle(10, 100, lerp(100, 350, x), lerp(200, 400, x), false);
			drawSetColour(0xFF);
			drawRectangle(lerp(200, 400, x), lerp(150, 300, x), 700, 750, false);
			drawSetColour(C.maroon);
			drawCircle(200, 450, lerp(20, 80, y), true);
			drawCircle(550, 160, lerp(10, 90, 1f-y), false);
		}
		endFrame();
	}
	
	quitAll();
}
