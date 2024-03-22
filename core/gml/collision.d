module gml.collision;

import std.algorithm.comparison, std.math, std.sumtype;

void init(){
	
}

void quit(){
	
}

enum BBoxKind{
	rectangular,         ///A rectangular (non-rotating) rectangle collision mask shape
	rectangularRotated,  ///A rectangular collision mask shape that rotates along with `imageAngle`
	ellipse,             ///An elliptical collision mask shape
	diamond,             ///A diamond collision mask shape
	precise,             ///A precise collision mask, where the mask will conform to the non-transparent pixels of the sprite
	precisePerFrame,     ///A precise collision mask that changes for each frame of the sprite
};
alias bboxkind = BBoxKind;

enum BBoxMode{
	automatic,              ///The bounding box will be calculated automatically, based on the tolerance setting for the sprite
	fullImage,              ///The bounding box will be set to use the full width and height of the sprite, regardless of the tolerance and "empty" pixels
	fullimage = fullImage,
	manual,                 ///The bounding box has been set manually to user defined values
}
alias bboxmode = BBoxMode;

N pointLineDistance(N)(N px, N py, N x1, N y1, N x2, N y2) nothrow @nogc pure @safe{
	N a = px - x1;
	N b = py - y1;
	N c = x2 - x1;
	N d = y2 - y1;
	N dot = a * c + b * d;
	N lenSq = c * c + d * d;
	N param = (lenSq != N(0)) ? dot/lenSq : N(-1); //in case of 0-length line
	
	N xx, yy;
	if(param < N(0)){
		xx = x1;
		yy = y1;
	}else if(param > N(1)){
		xx = x2;
		yy = y2;
	}else{
		xx = x1 + param * c;
		yy = y1 + param * d;
	}
	
	N dx = px - xx;
	N dy = py - yy;
	return cast(N)sqrt(dx * dx + dy * dy);
}

bool pointInRectangle(N)(
	N px, N py,
	N x1, N y1, N x2, N y2,
) nothrow @nogc pure @safe{
	if(x1 > x2){
		N x = x2;
		x2 = x1;
		x1 = x;
	}
	assert(x1 <= x2);
	if(y1 > y2){
		N y = y2;
		y2 = y1;
		y1 = y;
	}
	assert(y1 <= y2);
	return px >= x1 && px <= x2 && py >= y1 && py <= y2;
}
alias point_in_rectangle = pointInRectangle;

bool pointInTriangle(N)(
	N px, N py,
	N x1, N y1, N x2, N y2, N x3, N y3,
) nothrow @nogc pure @safe{
	
	N sign(N x1, N y1, N x2, N y2, N x3, N y3) =>
		(x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);
	N d1 = sign(px,py, x1,y1, x2,y2);
	N d2 = sign(px,py, x2,y2, x3,y3);
	N d3 = sign(px,py, x3,y3, x1,y1);
	
	return !(
		((d1 < N(0)) || (d2 < N(0)) || (d3 < N(0))) && //has negative
		((d1 > N(0)) || (d2 > N(0)) || (d3 > N(0)))    //has positive
	);
}
alias point_in_triangle = pointInTriangle;

bool pointInQuadrangle(N)(
	N px, N py,
	N x1, N y1, N x2, N y2, N x3, N y3, N x4, N y4,
) nothrow @nogc pure @safe =>
	pointInTriangle!N(px,py, x1,y1,x2,y2,x3,y3) ||
	pointInTriangle!N(px,py, x1,y1,x4,y4,x3,y3);

bool pointInCircle(N)(
	N px, N py,
	N cx, N cy, N rad,
) nothrow @nogc pure @safe{
	px -= cx;
	py -= cy;
	return (px*px + py*py) <= rad * rad;
}
alias point_in_circle = pointInCircle;

bool rectangleInRectangle(N)(
	N sx1, N sy1, N sx2, N sy2,
	N dx1, N dy1, N dx2, N dy2,
) nothrow @nogc pure @safe{
	if(sx1 > sx2){
		N sx = sx2;
		sx2 = sx1;
		sx1 = sx;
	}
	assert(sx1 <= sx2);
	if(sy1 > sy2){
		N sy = sy2;
		sy2 = sy1;
		sy1 = sy;
	}
	assert(sy1 <= sy2);
	if(dx1 > dx2){
		N dx = dx2;
		dx2 = dx1;
		dx1 = dx;
	}
	assert(dx1 <= dx2);
	if(dy1 > dy2){
		N dy = dy2;
		dy2 = dy1;
		dy1 = dy;
	}
	assert(dy1 <= dy2);
	return sx2 >= dx1 && sx1 <= dx2 && sy2 >= dy1 && sy1 <= dy2;
}
alias rectangle_in_rectangle = rectangleInRectangle;

//TODO: rectangle_in_triangle

//TODO: rectangle_in_circle

bool circleInCircle(N)(
	N x1, N y1, N rad1,
	N x2, N y2, N rad2,
) nothrow @nogc pure @safe{
	N distX = x1 - x2;
	N distY = y1 - y2;
	return distX*distX + distY*distY <= rad1*rad1 + rad2*rad2;
}
