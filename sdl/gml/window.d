module gml.window;

import gml.input, gml.room;

import std.exception, std.string;
import bindbc.sdl;

void init(){
	enforce(SDL_InitSubSystem(SDL_INIT_VIDEO) == 0, "SDL failed to initialise video: %s".format(SDL_GetError().fromStringz()));
	
	window = SDL_CreateWindow("",
		SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED,
		room.width, room.height,
		SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
	);
	enforce(window !is null, "SDL window creation error: %s".format(SDL_GetError().fromStringz()));
}

void quit(){
	SDL_QuitSubSystem(SDL_INIT_VIDEO);
}

SDL_Window* window;

///Returns `false` if the program should exit.
bool processEvents(){
	resetKeyStates();
	keyboardLastKey = keyboardKey;
	resetMouseStates();
	
	auto oldMB = mouseButton;
	
	SDL_Event event;
	while(SDL_PollEvent(&event)){
		switch(event.type){
			case SDL_WINDOWEVENT:
				switch(event.window.event){
					case SDL_WINDOWEVENT_SIZE_CHANGED:
						//onWindowResize(event.window.data1, event.window.data2);
						break;
					default:
				}
				break;
			case SDL_KEYDOWN:
				if(event.key.repeat != 0) break;
				gml.input.keyboard.setPressed(event.key.keysym.sym);
				VirtualKeyConstant vkKey;
				if(getVKCode(event.key.keysym.sym, vkKey)){
					keyboardKey = vkKey;
				}
				break;
			case SDL_KEYUP:
				gml.input.keyboard.setReleased(event.key.keysym.sym);
				VirtualKeyConstant vkKey;
				if(getVKCode(event.key.keysym.sym, vkKey)){
					if(vkKey == keyboardKey){
						keyboardKey = -1;
					}
				}
				break;
			case SDL_MOUSEBUTTONDOWN:
				gml.input.mouse.setPressed(event.button.button);
				mouseButton = SDL_BUTTON(event.button.button);
				break;
			case SDL_MOUSEBUTTONUP:
				gml.input.mouse.setReleased(event.button.button);
				if(mouseButton == SDL_BUTTON(event.button.button)){
					mouseButton = MB.none;
				}
				break;
			case SDL_QUIT:
				return false;
			default:
		}
	}
	
	if(oldMB != mouseButton){
		mouseLastButton = oldMB;
	}
	
	return true;
}

//Window Info

void* windowHandle() nothrow @nogc{
	SDL_SysWMinfo wmi;
	SDL_GetVersion(&wmi.version_);
	if(SDL_GetWindowWMInfo(window, &wmi)){
		switch(wmi.subsystem){
		version(linux){
			case SDL_SYSWM_X11:
				return cast(void*)wmi.info.x11.window;
			case SDL_SYSWM_WAYLAND:
				return SDL_GetWindowData(window, "wl_egl_window");
		}else version(OSX){
			case SDL_SYSWM_COCOA:
				SDL_MetalView view = SDL_Metal_CreateView(window);
				return SDL_Metal_GetLayer(view);
		}else version(iOS){
			case SDL_SYSWM_UIKIT:
				return wmi.info.uikit.window;
		}else version(Android){
			case SDL_SYSWM_ANDROID:
				return wmi.info.android.window;
		}else version(Windows){
			case SDL_SYSWM_WINDOWS:
				return wmi.info.win.window;
		}else static assert(0, "Getting a native window handle is unsupported on this platform!");
			default:
		}
	}
	return null;
}
alias window_handle = windowHandle;

//TODO: window_has_focus

//Mouse & Cursor

//TODO: window_mouse_get_x
//TODO: window_mouse_get_y
//TODO: window_mouse_get_delta_x
//TODO: window_mouse_get_delta_y
//TODO: window_mouse_set
//TODO: window_view_mouse_get_x
//TODO: window_view_mouse_get_y
//TODO: window_views_mouse_get_x
//TODO: window_views_mouse_get_y
//TODO: window_set_cursor
//TODO: window_get_cursor

//Mouse Lock

//TODO: window_mouse_set_locked
//TODO: window_mouse_get_locked

//Drawing

//TODO: window_set_colour
//TODO: window_get_colour

//Border & Caption

//TODO: window_set_caption
//TODO: window_get_caption
//TODO: window_set_showborder
//TODO: window_get_showborder
//TODO: window_enable_borderless_fullscreen
//TODO: window_get_borderless_fullscreen

//Dimensions & Position

//TODO: window_center
//TODO: window_get_fullscreen
//TODO: window_get_width
//TODO: window_get_height
//TODO: window_get_x
//TODO: window_get_y
//TODO: window_get_visible_rects
//TODO: window_set_fullscreen
//TODO: window_set_position
//TODO: window_set_size
//TODO: window_set_rectangle
//TODO: window_set_min_width
//TODO: window_set_max_width
//TODO: window_set_min_height
//TODO: window_set_max_height
