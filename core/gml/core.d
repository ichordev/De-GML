module gml.core;

public import
	gml.camera,
	gml.collision,
	gml.colour,
	gml.ds,
	gml.game,
	gml.layer,
	gml.maths,
	gml.options,
	gml.room,
	gml.sprite;

void init(){
	gml.collision.init();
	gml.colour.init();
	gml.ds.init();
	gml.layer.init();
	gml.game.init();
	gml.maths.init();
	gml.sprite.init();
}

void quit(){
	gml.sprite.quit();
	gml.maths.quit();
	gml.game.quit();
	gml.layer.quit();
	gml.ds.quit();
	gml.colour.quit();
	gml.collision.quit();
}
