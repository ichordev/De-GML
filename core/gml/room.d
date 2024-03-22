module gml.room;

import gml.base_object, gml.camera, gml.layer;

import std.algorithm.comparison;
import ic.vec;

void init(){
	roomStart(&orderedRooms[0]);
}

void quit(){
	roomEnd();
}

Room[] orderedRooms;
Room roomData;

struct Room{
	string name;
	Vec2!uint size = Vec2!uint(1366, 768);
	bool persistent = false;
	bool useViews = false;
	enum viewCount = 8;
	Viewport[viewCount] viewports;
	BaseObject[] instances;
	
	@property Vec2!uint windowSize() nothrow @nogc pure @safe{
		if(useViews){
			//technically there should be a 'windowPos' property, used to account for a `minPos` of >0, but GameMaker doesn't account for this at all!
			auto minPos = Vec2!uint(uint.max, uint.max);
			Vec2!uint maxPos;
			foreach(viewport; viewports){
				if(viewport.visible){
					const portMaxPos = viewport.pos + viewport.size;
					minPos.x = min(minPos.x, viewport.pos.x);
					minPos.y = min(minPos.y, viewport.pos.y);
					maxPos.x = max(maxPos.x, portMaxPos.x);
					maxPos.y = max(maxPos.y, portMaxPos.y);
				}
			}
			if(minPos == vec2(uint.max, uint.max)){
				return size;
			}else{
				return maxPos - minPos;
			}
		}else{
			return size;
		}
	}
}

alias RoomAsset = Room*;

void roomStart(RoomAsset newRoom){
	room = newRoom;
	roomData = *newRoom;
	roomData.instances = new BaseObject[](newRoom.instances.length);
	foreach(i, instance; newRoom.instances){
		//roomData.instances = instance.dup;
	}
}

void roomEnd(){
	room = null;
	roomData = Room.init;
}

//Global

@property RoomAsset roomFirst() nothrow @nogc @safe =>
	&orderedRooms[0];
alias room_first = roomFirst;

@property RoomAsset roomLast() nothrow @nogc @safe =>
	&orderedRooms[$-1];
alias room_last = roomLast;

RoomAsset roomNext(RoomAsset numb) nothrow @nogc{
	if(numb >= &orderedRooms[$-1] || numb < &orderedRooms[0]){
		return null;
	}
	return numb+1;
}
alias room_next = roomNext;

RoomAsset roomPrevious(RoomAsset numb) nothrow @nogc{
	if(numb <= &orderedRooms[0] || numb > &orderedRooms[$-1]){
		return null;
	}
	return numb-1;
}
alias room_previous = roomNext;

RoomAsset room;

alias roomHeight = roomData.size.y;
alias room_height = roomHeight;

alias roomWidth = roomData.size.x;
alias room_width = roomWidth;

//Information

bool roomExists(RoomAsset index) nothrow @nogc pure @safe =>
	index !is null;
alias room_exists = roomExists;

string roomGetName(RoomAsset index) nothrow @nogc pure @safe =>
	index.name;
alias room_get_name = roomGetName;

//TODO: room_get_info

//Switching Rooms

void roomGoto(RoomAsset index){
	roomEnd();
	roomStart(index);
}
alias room_goto = roomGoto;

void roomGotoNext(){
	roomEnd();
	if(auto nextRoom = roomNext(room)){
		roomStart(nextRoom);
	}else{
		throw new Exception("Tried to use `roomGotoNext` from the last room");
	}
}
alias room_goto_next = roomGotoNext;

void roomGotoPrevious(){
	roomEnd();
	if(auto prevRoom = roomPrevious(room)){
		roomStart(prevRoom);
	}else{
		throw new Exception("Tried to use `roomGotoPrevious` from the first room");
	}
}
alias room_goto_previous = roomGotoPrevious;

void roomRestart(){
	roomEnd();
	roomStart(room);
}

//Modifying Rooms

RoomAsset roomAdd() nothrow pure @safe =>
	new Room();
alias room_add = roomAdd;

RoomAsset roomAddOrdered() nothrow @safe{
	orderedRooms ~= Room();
	return &orderedRooms[$-1];
}

RoomAsset roomDuplicate() nothrow @safe{
	auto newRoom = roomAdd();
	roomAssign(newRoom, room);
	return newRoom;
}
alias room_duplicate = roomDuplicate;

void roomAssign(RoomAsset ind, RoomAsset source) nothrow @nogc pure @safe{
	*ind = *source;
}
alias room_assign = roomAssign;
