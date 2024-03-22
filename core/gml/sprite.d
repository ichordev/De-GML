module gml.sprite;

import gml.collision;

import std.algorithm.comparison;
import ic.vec;

void init(){
	
}

void quit(){
	
}

enum SpriteSpeed{
	framesPerSecond,     ///The sprite was defined with animation in frames per second.
	framesPerGameFrame,  ///The sprite was defined with in animation in frames per game frame.
}
alias spritespeed = SpriteSpeed;

alias TextureID = size_t;

struct Image{
	TextureID textureID;
	float[4] uvs = [0f,0f, 1f,1f];
	int duration; //TODO: what exactly does this store?
}

struct Sprite{
	string name;
	Vec2!uint size;
	Vec2!int offset;
	Image[] images;
	
	SpriteSpeed speedType = SpriteSpeed.framesPerGameFrame;
	float speed = 1f;
	
	Vec2!int bboxPos;
	Vec2!uint bboxSize;
	BBoxKind maskType;
	BBoxMode maskMode;
	ubyte tolerance = 0;
}

alias SpriteAsset = Sprite*;

//Sprite Information

bool spriteExists(SpriteAsset index) nothrow @nogc pure @safe =>
	index !is null;
alias sprite_exists = spriteExists;

string spriteGetName(SpriteAsset index) nothrow @nogc pure @safe =>
	index.name;
alias sprite_get_name = spriteGetName;

size_t spriteGetNumber(SpriteAsset index) nothrow @nogc pure @safe =>
	index.images.length;
alias sprite_get_number = spriteGetNumber;

float spriteGetSpeed(SpriteAsset index) nothrow @nogc pure @safe =>
	index.speed;
alias sprite_get_speed = spriteGetSpeed;

SpriteSpeed spriteGetSpeedType(SpriteAsset index) nothrow @nogc pure @safe =>
	index.speedType;
alias sprite_get_speed_type = spriteGetSpeedType;

uint spriteGetWidth(SpriteAsset index) nothrow @nogc pure @safe =>
	index.size.x;
alias sprite_get_width = spriteGetWidth;

uint spriteGetHeight(SpriteAsset index) nothrow @nogc pure @safe =>
	index.size.y;
alias sprite_get_height = spriteGetHeight;

int spriteGetXOffset(SpriteAsset index) nothrow @nogc pure @safe =>
	index.offset.x;
alias sprite_get_xoffset = spriteGetXOffset;

int spriteGetYOffset(SpriteAsset index) nothrow @nogc pure @safe =>
	index.offset.y;
alias sprite_get_yoffset = spriteGetYOffset;

int spriteGetBBoxBottom(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.bboxPos.y + cast(int)ind.bboxSize.y;
alias sprite_get_bbox_bottom = spriteGetBBoxBottom;

int spriteGetBBoxLeft(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.bboxPos.x;
alias sprite_get_bbox_left = spriteGetBBoxLeft;

int spriteGetBBoxRight(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.bboxPos.x + cast(int)ind.bboxSize.x;
alias sprite_get_bbox_right = spriteGetBBoxRight;

int spriteGetBBoxTop(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.bboxPos.y;
alias sprite_get_bbox_top = spriteGetBBoxTop;

BBoxMode spriteGetBBoxMode(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.maskMode;
alias sprite_get_bbox_mode = spriteGetBBoxMode;

BBoxKind spriteGetBBoxKind(SpriteAsset ind) nothrow @nogc pure @safe =>
	ind.maskType;

//TODO: sprite_get_nineslice

//TODO: sprite_get_tpe

float[4] spriteGetUVs(SpriteAsset sprite, size_t subImage) nothrow @nogc pure @safe =>
	sprite.images[subImage].uvs;
alias sprite_get_uvs = spriteGetUVs;

//TODO: sprite_get_info

//Asset Properties

void spriteCollisionMask(SpriteAsset ind, bool sepMasks, BBoxMode bboxMode, int bbLeft, int bbTop, int bbRight, int bbBottom, BBoxKind kind, ubyte tolerance) nothrow @nogc pure @safe{
	ind.maskType = kind;
	ind.tolerance = tolerance;
	
	//TODO: how does sepMasks work?
	spriteSetBBoxMode(ind, bboxMode);
	if(bboxMode == BBoxMode.manual){
		spriteSetBBox(ind, bbLeft, bbTop, bbRight, bbBottom);
	}
}
alias sprite_collision_mask = spriteCollisionMask;

void spriteSetOffset(SpriteAsset ind, int xOff, int yOff) nothrow @nogc pure @safe{
	ind.offset = Vec2!int(xOff, yOff);
}
alias sprite_set_offset = spriteSetOffset;

void spriteSetBBoxMode(SpriteAsset ind, BBoxMode mode) nothrow @nogc pure @safe{
	with(BBoxMode) final switch(mode){
		case automatic:
			//TODO: calculate this somehow... it will probably require moving this function
			break;
		case fullImage:
			ind.bboxPos = Vec2!int(0, 0);
			ind.bboxSize = ind.size;
			break;
		case manual:
			break;
	}
}
alias sprite_set_bbox_mode = spriteSetBBoxMode;

void spriteSetBBox(SpriteAsset ind, int left, int top, int right, int bottom) nothrow @nogc pure @safe{
	ind.maskMode = BBoxMode.manual;
	ind.bboxPos = Vec2!int(left, top);
	ind.bboxSize.x = max(right, left) - left;
	ind.bboxSize.y = max(bottom, top) - top;
}
alias sprite_set_bbox = spriteSetBBox;

SpriteSpeed spriteSetSpeed(SpriteAsset index, float speed, SpriteSpeed type) nothrow @nogc pure @safe{
	index.speed = speed;
	index.speedType = type;
	return type;
}

//TODO: sprite_set_nineslice

//Creating & Modifying Sprites

//put this stuff in a new module that depends on SDL_image!
