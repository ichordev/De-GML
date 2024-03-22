module gml.draw.forms;

import gml.camera, gml.colour, gml.draw;

import std.algorithm.comparison, std.math;
import ic.calc, ic.vec;

void init(){
	
}

void quit(){
	
}

import bindbc.bgfx;

void drawVerts(VertPos[] verts, StatePT state=cast(StatePT)0) nothrow{
	const vertNum = bgfx.getAvailTransientVertexBuffer(cast(uint)verts.length, VertPos.layout);
	if(vertNum == 0) return;
	bgfx.TransientVertexBuffer buffer;
	bgfx.allocTransientVertexBuffer(&buffer, vertNum, VertPos.layout);
	
	bgfx.setUniform(u_colour, &gpuState.col);
	
	auto bufferData = (cast(VertPos*)buffer.data)[0..vertNum];
	foreach(i, vert; verts[0..vertNum]){
		bufferData[i] = vert;
	}
	bgfx.setVertexBuffer(0, &buffer);
	bgfx.setState(gpuState.getBgfxState() | state);
	const transform = gpuState.getTransform();
	bgfx.setTransform(&transform);
	bgfx.submit(gpuState.bgfxView, gpuState.program);
}

void drawVerts(VertPosCol[] verts, StatePT state=cast(StatePT)0) nothrow{
	const vertNum = bgfx.getAvailTransientVertexBuffer(cast(uint)verts.length, VertPosCol.layout);
	if(vertNum == 0) return;
	TransientVertexBuffer buffer;
	bgfx.allocTransientVertexBuffer(&buffer, vertNum, VertPosCol.layout);
	
	auto bufferData = (cast(VertPosCol*)buffer.data)[0..vertNum];
	foreach(i, vert; verts[0..vertNum]){
		bufferData[i] = vert;
	}
	bgfx.setVertexBuffer(0, &buffer);
	bgfx.setState(gpuState.getBgfxState() | state);
	const transform = gpuState.getTransform();
	bgfx.setTransform(&transform);
	bgfx.submit(gpuState.bgfxView, shPassPosCol);
}

void drawVerts(VertPosColTex[] verts, StatePT state=cast(StatePT)0) nothrow{
	const vertNum = bgfx.getAvailTransientVertexBuffer(cast(uint)verts.length, VertPosColTex.layout);
	if(vertNum == 0 || vertNum > verts.length) return;
	
	TransientVertexBuffer buffer;
	bgfx.allocTransientVertexBuffer(&buffer, vertNum, VertPosColTex.layout);
	
	auto bufferData = (cast(VertPosColTex*)buffer.data)[0..vertNum];
	foreach(i, vert; verts[0..vertNum]){
		bufferData[i] = vert;
	}
	bgfx.setVertexBuffer(0, &buffer);
	bgfx.setState(gpuState.getBgfxState() | state);
	const transform = gpuState.getTransform();
	bgfx.setTransform(&transform);
	bgfx.submit(gpuState.bgfxView, gpuState.program);
}

void drawCircle(float x, float y, float radius, bool outline) nothrow{
	VertPos[] verts;
	if(outline){
		verts.length = circlePrecision+1;
		{
			const vert = VertPos(x + cos(0.0) * radius, y + sin(0.0) * radius);
			verts[0]   = vert;
			verts[$-1] = vert;
		}
		double dir = 0.0;
		foreach(ref vert; verts[0..$-1]){
			vert = VertPos(x + cos(dir) * radius, y + sin(dir) * radius);
			dir += (PI*2.0) / cast(double)circlePrecision;
		}
		
		drawVerts(verts, StatePT.lineStrip);
	}else{
		verts.length = circlePrecision*3;
		double dir = 0.0;
		for(size_t i=0; i<verts.length; i+=3){
			verts[i+0] = VertPos(x, y);
			verts[i+1] = VertPos(x + cos(dir) * radius, y + sin(dir) * radius);
			dir += (PI*2.0) / cast(double)circlePrecision;
			verts[i+2] = VertPos(x + cos(dir) * radius, y + sin(dir) * radius);
		}
		drawVerts(verts);
	}
}
alias draw_circle = drawCircle;

void drawCircleColour(float x, float y, float radius, uint col1, uint col2, bool outline) nothrow{
	VertPosCol[] verts;
	if(outline){
		verts.length = circlePrecision+1;
		{
			const vert = VertPosCol(x + cos(0.0) * radius, y + sin(0.0) * radius, col2);
			verts[0]   = vert;
			verts[$-1] = vert;
		}
		double dir = 0.0;
		foreach(ref vert; verts[0..$-1]){
			vert = VertPosCol(x + cos(dir) * radius, y + sin(dir) * radius, col2);
			dir += (PI*2.0) / cast(double)circlePrecision;
		}
		
		drawVerts(verts, StatePT.lineStrip);
	}else{
		verts.length = circlePrecision*3;
		double dir = 0.0;
		for(size_t i=0; i<verts.length; i+=3){
			verts[i+0] = VertPosCol(x, y, col1);
			verts[i+1] = VertPosCol(x + cos(dir) * radius, y + sin(dir) * radius, col2);
			dir += (PI*2.0) / cast(double)circlePrecision;
			verts[i+2] = VertPosCol(x + cos(dir) * radius, y + sin(dir) * radius, col2);
		}
		drawVerts(verts);
	}
}
alias draw_circle_colour = drawCircleColour;


void drawPoint(float x, float y) nothrow{
	drawVerts([VertPos(x, y)], StatePT.points);
}
alias draw_point = drawPoint;

void drawLine(float x1, float y1, float x2, float y2) nothrow{
	drawVerts([
		VertPos(x1, y1),
		VertPos(x2, y2),
	], StatePT.lines);
}
alias draw_line = drawLine;

void drawRectangle(float x1, float y1, float x2, float y2, bool outline) nothrow{
	if(outline){
		drawVerts([
			VertPos(x1, y1),
			VertPos(x2, y1),
			VertPos(x2, y2),
			VertPos(x1, y2),
			VertPos(x1, y1),
		], StatePT.lineStrip);
	}else{
		drawVerts([
			VertPos(x1, y1),
			VertPos(x2, y1),
			VertPos(x1, y2),
			VertPos(x2, y2),
		], StatePT.triStrip);
	}
}
alias draw_rectangle = drawRectangle;

void drawTriangle(float x1, float y1, float x2, float y2, float x3, float y3, bool outline) nothrow{
	if(outline){
		drawVerts([
			VertPos(x1, y1),
			VertPos(x2, y2),
			VertPos(x3, y3),
			VertPos(x1, y1),
		], StatePT.lineStrip);
	}else{
		drawVerts([
			VertPos(x1, y1),
			VertPos(x2, y2),
			VertPos(x3, y3),
		], StatePT.triStrip);
	}
}
alias draw_triangle = drawTriangle;

// ,------------------------------------------------------------------------------------------------------------------,
// | NOTE: most of the following code code assumes x/y1 is top left. Please rewrite it where this does not hold true. |
// '------------------------------------------------------------------------------------------------------------------'

void drawArrow(float x1, float y1, float x2, float y2, float size) nothrow{
	const dir = atan2(y1-y2, x1-x2);
	drawLine(x1, y1, x2, y2);
	drawTriangle(
		x2 + cos(dir)*size,
		y2 + sin(dir)*size,
		x2 + cos(dir-pi2)*size,
		y2 + sin(dir-pi2)*size,
		x2 + cos(dir+pi2)*size,
		y2 + sin(dir+pi2)*size,
		false,
	);
}
alias draw_arrow = drawArrow;

void drawButton(float x1, float y1, float x2, float y2, bool up) nothrow{
	enum margin = 2f;
	const stateAlpha = gpuState.intCol & 0xFF_00_00_00;
	const col1 = (up ? C.ltGrey : C.dkGrey) | stateAlpha;
	const col2 = (up ? C.dkGrey : C.ltGrey) | stateAlpha;
	drawVerts([
		//inner area
		VertPosCol(x1, y1, gpuState.intCol),
		VertPosCol(x2, y1, gpuState.intCol),
		VertPosCol(x1, y2, gpuState.intCol),
		
		VertPosCol(x2, y1, gpuState.intCol),
		VertPosCol(x1, y2, gpuState.intCol),
		VertPosCol(x2, y2, gpuState.intCol),
		//top
		VertPosCol(x1, y1, col1),
		VertPosCol(x1-margin, y1-margin, col1),
		VertPosCol(x2+margin, y1-margin, col1),
		
		VertPosCol(x1, y1, col1),
		VertPosCol(x2+margin, y1-margin, col1),
		VertPosCol(x2, y1, col1),
		//left
		VertPosCol(x1, y1, col1),
		VertPosCol(x1-margin, y1-margin, col1),
		VertPosCol(x1-margin, y2+margin, col1),
		
		VertPosCol(x1, y1, col1),
		VertPosCol(x1-margin, y2+margin, col1),
		VertPosCol(x1, y2, col1),
		//bottom
		VertPosCol(x1, y2, col2),
		VertPosCol(x1-margin, y2+margin, col2),
		VertPosCol(x2+margin, y2+margin, col2),
		
		VertPosCol(x1, y2, col2),
		VertPosCol(x2+margin, y2+margin, col2),
		VertPosCol(x2, y2, col2),
		//right
		VertPosCol(x2, y1, col2),
		VertPosCol(x2+margin, y1-margin, col2),
		VertPosCol(x2+margin, y2+margin, col2),
		
		VertPosCol(x2, y1, col2),
		VertPosCol(x2+margin, y2+margin, col2),
		VertPosCol(x2, y2, col2),
	]);
}

void drawEllipse(float x1, float y1, float x2, float y2, bool outline) nothrow{
	//TODO: outline :P
	const rad = Vec2!float(
		(x2-x1) / 2f,
		(y2-y1) / 2f,
	);
	const centre = Vec2!float(
		x1 + rad.x,
		y1 + rad.y,
	);
	const dirMul = pi / cast(float)(circlePrecision-1);
	auto prevPos = Vec2!float(centre.x, centre.y-rad.y);
	auto verts = new VertPos[](circlePrecision * 3);
	for(size_t i=1; i<circlePrecision; i+=3){
		const dir = i * dirMul;
		const pos = Vec2!float(
			centre.x + cos(dir)*rad.x,
			centre.y + sin(dir)*rad.y,
		);
		verts[i+0]= VertPos(centre.x, centre.y);
		verts[i+1]= VertPos(prevPos.x, prevPos.y);
		verts[i+2]= VertPos(pos.x, pos.y);
		prevPos = pos;
	}
	drawVerts(verts);
}
alias draw_ellipse = drawEllipse;

void drawEllipseColour(float x1, float y1, float x2, float y2, uint col1, uint col2, bool outline) nothrow{
	//TODO: outline :P
	const rad = Vec2!float(
		(x2-x1) / 2f,
		(y2-y1) / 2f,
	);
	const centre = Vec2!float(
		x1 + rad.x,
		y1 + rad.y,
	);
	const dirMul = pi / cast(float)(circlePrecision-1);
	auto prevPos = Vec2!float(centre.x, centre.y-rad.y);
	auto verts = new VertPosCol[](circlePrecision * 3);
	for(size_t i=1; i<circlePrecision; i+=3){
		const dir = i * dirMul;
		const pos = Vec2!float(
			centre.x + cos(dir)*rad.x,
			centre.y + sin(dir)*rad.y,
		);
		verts[i+0]= VertPosCol(centre.x, centre.y, col1);
		verts[i+1]= VertPosCol(prevPos.x, prevPos.y, col2);
		verts[i+2]= VertPosCol(pos.x, pos.y, col2);
		prevPos = pos;
	}
	drawVerts(verts);
}
alias draw_ellipse_colour = drawEllipseColour;

void drawLineWidth(float x1, float y1, float x2, float y2, float w) nothrow{
	const dir = atan2(y1-y2, x1-x2);
	drawVerts([
		VertPos(x1 + cos(dir+pi2)*w, y1 + sin(dir+pi2)*w),
		VertPos(x1 + cos(dir-pi2)*w, y1 + sin(dir-pi2)*w),
		
		VertPos(x2 + cos(dir+pi2)*w, y2 + sin(dir+pi2)*w),
		VertPos(x2 + cos(dir-pi2)*w, y2 + sin(dir-pi2)*w),
	], StatePT.triStrip);
}

void drawLineWidthColour(float x1, float y1, float x2, float y2, float w, uint col1, uint col2) nothrow{
	const dir = atan2(y1-y2, x1-x2);
	drawVerts([
		VertPosCol(x1 + cos(dir+pi2)*w, y1 + sin(dir+pi2)*w, col1),
		VertPosCol(x1 + cos(dir-pi2)*w, y1 + sin(dir-pi2)*w, col1),
		
		VertPosCol(x2 + cos(dir+pi2)*w, y2 + sin(dir+pi2)*w, col2),
		VertPosCol(x2 + cos(dir-pi2)*w, y2 + sin(dir-pi2)*w, col2),
	], StatePT.triStrip);
}

uint circlePrecision = 24;
void drawSetCirclePrecision(uint precision) nothrow @nogc @safe{
	circlePrecision = max(precision - (precision % 4), 4);
}
alias draw_set_circle_precision = drawSetCirclePrecision;
