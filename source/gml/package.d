module gml;

public import
	gml.core,
	gml.sdl,
	gml.bgfx;

/**
Before calling this function:
- You must have declared at least one room. (e.g. using `roomAddOrdered()`)
*/
void initAll(){
	gml.core.init();
	gml.sdl.init();
	gml.bgfx.init();
}

void quitAll(){
	gml.bgfx.quit();
	gml.sdl.quit();
	gml.core.quit();
}
