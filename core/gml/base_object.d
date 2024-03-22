module gml.base_object;

import gml.layer, gml.maths, gml.room, gml.sprite;

import core.memory;
import std.math;

void init(){
	
}

void quit(){
	self = null;
	other = null;
}

class BaseObject{
	bool visible = true;
	bool solid;
	const bool persistent;
	float depth = float.nan; //sets gpuState.depth
	LayerID layer;
	int[12] alarm;
	
	final @property double direction() nothrow @nogc pure @safe => datan2(vSpeed, hSpeed);
	final @property direction(double val) nothrow @nogc pure @safe{
		const rad = val.degToRad();
		const s = speed;
		hSpeed = cos(rad) * s;
		vSpeed = sin(rad) * s;
	}
	double friction = 0.0;
	double gravity = 0.0;
	double gravityDirection = 0.0;
	alias gravity_direction = gravityDirection;
	double hSpeed;
	alias hspeed = hSpeed;
	double vSpeed;
	alias vspeed = vSpeed;
	final @property double speed() nothrow @nogc pure @safe => sqrt(hSpeed*hSpeed + vSpeed*vSpeed);
	final @property speed(double val) nothrow @nogc pure @safe{
		const rad = atan2(vSpeed, hSpeed);
		hSpeed = cos(rad) * val;
		vSpeed = sin(rad) * val;
	}
	double xStart = 0.0;
	alias xstart = xStart;
	double yStart = 0.0;
	alias ystart = yStart;
	double x = 0.0;
	double y = 0.0;
	double xPrevious;
	alias xprevious = xPrevious;
	double yPrevious;
	alias yprevious = yPrevious;
	
	SpriteAsset spriteIndex;
	alias sprite_index = spriteIndex;
	@property double spriteWidth() nothrow @nogc pure @safe => double.nan;
	alias sprite_width = spriteWidth;
	@property double spriteHeight() nothrow @nogc pure @safe => double.nan;
	alias sprite_height = spriteHeight;
	@property double spriteXOffset() nothrow @nogc pure @safe => double.nan;
	alias sprite_xoffset = spriteXOffset;
	@property double spriteYOffset() nothrow @nogc pure @safe => double.nan;
	alias sprite_yoffset = spriteYOffset;
	float imageAlpha = 1f;
	alias image_alpha = imageAlpha;
	double imageAngle = 0.0;
	alias image_angle = imageAngle;
	uint imageBlend = 0xFF_FF_FF;
	alias image_blend = imageBlend;
	float imageIndex = 0f;
	alias image_index = imageIndex;
	@property size_t imageNumber() => spriteGetNumber(spriteIndex);
	alias image_number = imageNumber;
	float imageSpeed = 1f;
	alias image_speed = imageSpeed;
	double imageXScale = 1.0;
	alias image_xscale = imageXScale;
	double imageYScale = 1.0;
	alias image_yscale = imageYScale;
	
	SpriteAsset maskIndex;
	alias mask_index = maskIndex;
	@property int bboxBottom() nothrow @nogc pure @safe => cast(int)ceil(y);
	alias bbox_bottom = bboxBottom;
	@property int bboxLeft() nothrow @nogc pure @safe => cast(int)floor(x);
	alias bbox_left = bboxLeft;
	@property int bboxRight() nothrow @nogc pure @safe => cast(int)ceil(x);
	alias bbox_right = bboxRight;
	@property int bboxTop() nothrow @nogc pure @safe => cast(int)floor(y);
	alias bbox_top = bboxTop;
	
	this(bool persistent) nothrow pure @safe{
		this.persistent = persistent;
	}
	
	void instanceDestroy(){
		.instanceDestroy(this);
	}
	alias instance_destroy = instanceDestroy;
	
	void builtInStep(){
		//TODO: this
	}
	
	void drawSelf(){}
	alias draw_self = drawSelf;
	
	void onPreStep(){}
	void onStep(){}
	void onPostStep(){}
	
	void onDraw(){
		drawSelf();
	}
	
	void onAlarm0(){}
	void onAlarm1(){}
	void onAlarm2(){}
	void onAlarm3(){}
	void onAlarm4(){}
	void onAlarm5(){}
	void onAlarm6(){}
	void onAlarm7(){}
	void onAlarm8(){}
	void onAlarm9(){}
	void onAlarm10(){}
	void onAlarm11(){}
	void onAlarm12(){}
	
	void onGameStart(){}
	void onGameEnd(){}
	
	void onRoomStart(){}
	void onRoomEnd(){}
	
	void onDestroy(){}
}

BaseObject self;
BaseObject other;

Obj instanceCreateLayer(Obj)(double x, double y, LayerID layerID) nothrow pure @safe{
	auto obj = new Obj();
	obj.x = x;
	obj.y = y;
	obj.layer = layerID;
}
Obj instanceCreateLayer(Obj)(double x, double y, string layerID) @safe{
	auto obj = new Obj();
	obj.x = x;
	obj.y = y;
	obj.layer = layerGetID(layerID);
}
alias instance_create_layer = instanceCreateLayer;

Obj instanceCreateDepth(Obj)(double x, double y, float depth){
	auto obj = new Obj();
	obj.x = x;
	obj.y = y;
	obj.depth = depth;
}
alias instance_create_depth = instanceCreateDepth;

void instanceDestroy(Obj)(Obj id, bool executeEventFlag=true){
	if(executeEventFlag){
		id.onDestroy();
	}
	//TODO: Add to room instance free queue
}
alias instance_destroy = instanceDestroy;
