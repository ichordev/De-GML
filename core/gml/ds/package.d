module gml.ds;

public import
	gml.ds.grid,
	gml.ds.list,
	gml.ds.map,
	gml.ds.priority,
	gml.ds.queue,
	gml.ds.stack;

void init(){
	gml.ds.grid.init();
	gml.ds.list.init();
	gml.ds.map.init();
	gml.ds.priority.init();
	gml.ds.queue.init();
	gml.ds.stack.init();
}

void quit(){
	gml.ds.stack.quit();
	gml.ds.queue.quit();
	gml.ds.priority.quit();
	gml.ds.map.quit();
	gml.ds.list.quit();
	gml.ds.grid.quit();
}

double dsPrecision = 0.00_00_00_1;

void dsSetPrecision(double prec) nothrow @nogc @safe{
	dsPrecision = prec;
}
alias ds_set_precision = dsSetPrecision;

enum DSType{
	map,       //A map data structure.
	list,      //A list data structure.
	stack,     //A stack data structure.
	grid,      //A grid data structure.
	queue,     //A queue data structure.
	priority,  //A priority data structure.
}
alias ds_type = DSType;

bool dsExists(T)(T ind, DSType type) nothrow @nogc pure @safe{
	static if(is(T: DSGrid)){
		return type == DSType.grid;
	}else static if(is(T: DSList)){
		return type == DSType.list;
	}else static if(is(T: DSMap)){
		return type == DSType.map;
	}else static if(is(T: DSPriority)){
		return type == DSType.priority;
	}else static if(is(T: DSQueue)){
		return type == DSType.queue;
	}else static if(is(T: DSStack)){
		return type == DSType.stack;
	}else static assert(0, "Bad `ind` type: "~typeof(ind).stringof);
}
alias ds_exists = dsExists;
