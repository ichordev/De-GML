module gml.core;

public import
	gml.camera,
	gml.collision,
	gml.ds,
	gml.game,
	gml.maths,
	gml.options,
	gml.room;

void init(){
	gml.collision.init();
	gml.ds.init();
	gml.game.init();
	gml.maths.init();
}

void quit(){
	gml.maths.quit();
	gml.game.quit();
	gml.ds.quit();
	gml.collision.quit();
}
