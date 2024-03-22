module gml.colour;

import std.algorithm.comparison, std.math;
import ic.ease: lerp;

void init(){
	
}

void quit(){
	
}

enum C{
	aqua     = 0xFF_FF_00,
	black    = 0x00_00_00,
	blue     = 0xFF_00_00,
	dkGrey   = 0x40_40_40,
	fuchsia  = 0xFF_00_FF,
	grey     = 0x80_80_80,
	gray     = grey,
	green    = 0x00_80_00,
	lime     = 0x00_FF_00,
	ltGrey   = 0xC0_C0_C0,
	maroon   = 0x00_00_80,
	navy     = 0x80_00_00,
	olive    = 0x00_80_80,
	orange   = 0x40_A0_FF,
	purple   = 0x80_00_80,
	red      = 0x00_00_FF,
	silver   = 0xC0_C0_C0,
	teal     = 0x80_80_00,
	white    = 0xFF_FF_FF,
	yellow   = 0x00_FF_FF,
}
alias c = C;

///Reverses a colour's bytes, so that you can plug `col(0xRRGGBB)` into the functions below.
uint col(uint bgr) nothrow @nogc pure @safe =>
	((bgr & 0xFF) << 16) | (bgr & 0xFF_00) | ((bgr & 0xFF_00_00) >> 16);

//Get colour values

ubyte colourGetBlue(uint col) nothrow @nogc pure @safe =>
	cast(ubyte)((col & 0xFF_00_00) >> 16);
alias colour_get_blue = colourGetBlue;

ubyte colourGetGreen(uint col) nothrow @nogc pure @safe =>
	cast(ubyte)((col & 0xFF_00) >> 8);
alias colour_get_green = colourGetGreen;

ubyte colourGetRed(uint col) nothrow @nogc pure @safe =>
	cast(ubyte)(col & 0xFF);
alias colour_get_red = colourGetRed;

ubyte colourGetHue(uint col) nothrow @nogc pure @safe{
	const r = colourGetRed(col);
	const g = colourGetGreen(col);
	const b = colourGetBlue(col);
	const colMax = max(r, g, b);
	const colMin = colMax - min(r, g, b);
	const float h = colMin > 0 ? (
		(colMax == r) ?
			0f + (g - b) / cast(float)colMin : (
		(colMax == g) ?
			2f + (b - r) / cast(float)colMin :
			4f + (r - g) / cast(float)colMin)
	) : 0f;
	return cast(ubyte)round(42.5f * (h < 0f ? h + 6f : h));
}
alias colour_get_hue = colourGetHue;
unittest{
	assert(colourGetHue(makeColourHSV( 80, 125, 255)) ==  80);
	assert(colourGetHue(makeColourHSV(250, 125, 128)) == 250);
}

ubyte colourGetSaturation(uint col) nothrow @nogc pure @safe{
	const r = colourGetRed(col);
	const g = colourGetGreen(col);
	const b = colourGetBlue(col);
	const colMax = max(r, g, b);
	const colMin = colMax - min(r, g, b);
	return colMax > 0 ? cast(ubyte)round((colMin / cast(float)colMax) * 255f) : 0;
}
alias colour_get_saturation = colourGetSaturation;
unittest{
	assert(colourGetSaturation(makeColourHSV( 80, 125, 255)) == 125);
	assert(colourGetSaturation(makeColourHSV(250,   0, 128)) ==   0);
}

ubyte colourGetValue(uint col) nothrow @nogc pure @safe{
	const r = colourGetRed(col);
	const g = colourGetGreen(col);
	const b = colourGetBlue(col);
	const colMax = max(r, g, b);
	return colMax;
}
alias colour_get_value = colourGetValue;
unittest{
	assert(colourGetValue(makeColourHSV( 80, 125, 255)) == 255);
	assert(colourGetValue(makeColourHSV(250,   0, 128)) == 128);
	assert(colourGetValue(makeColourHSV( 64,  80,   0)) ==   0);
}

//TODO: draw_getpixel

//TODO: draw_getpixel_ext

//Create colours from raw input values

uint makeColourHSV(float hue, float sat, float val) nothrow @nogc pure @safe{
	sat /= 255f;
	val /= 255f;
	const hueDiv = hue / 42.5f; //TODO: This means that hue=255 is the same as hue=0. Is this correct?
	float f(float n) nothrow @nogc pure @safe{
		const k = (n + hueDiv) % 6f;
		return val - val * sat * max(min(k, 4f-k, 1f), 0f);
	}
	return makeColourRGB(f(5f) * 255f, f(3f) * 255f, f(1f) * 255f);
}
alias make_colour_hsv = makeColourHSV;
unittest{
	assert(makeColourHSV(255.0, 255.0, 255.0) == 0x00_00_FF);
	assert(makeColourHSV(127.5, 127.5, 255.0) == 0xFF_FF_80);
}

uint makeColourRGB(float red, float green, float blue) nothrow @nogc pure @safe =>
	(min(cast(uint)round(red),   255) <<  0) |
	(min(cast(uint)round(green), 255) <<  8) |
	(min(cast(uint)round(blue),  255) << 16);
alias make_colour_rgb = makeColourRGB;

uint mergeColour(uint col1, uint col2, double amount) nothrow @nogc pure @safe{
	float[3] c1f = [
		(col1 >>  0) & 0xFF,
		(col1 >>  8) & 0xFF,
		(col1 >> 16) & 0xFF,
	];
	float[3] c2f = [
		(col2 >>  0) & 0xFF,
		(col2 >>  8) & 0xFF,
		(col2 >> 16) & 0xFF,
	];
	return
		(cast(ubyte)lerp(c1f[0], c2f[0], amount) <<  0) |
		(cast(ubyte)lerp(c1f[1], c2f[1], amount) <<  8) |
		(cast(ubyte)lerp(c1f[2], c2f[2], amount) << 16);
}
alias merge_colour = mergeColour;
