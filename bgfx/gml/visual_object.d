module gml.visual_object;

import gml.base_object, gml.sprite;

class VisualObject: BaseObject{
	this(bool persistent) nothrow pure @safe{
		super(persistent);
	}
	
	override void drawSelf(){
		//TODO: this
	}
}
