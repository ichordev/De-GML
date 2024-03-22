# Dependent Game Making Library

De-GML is here to help (former) GameMaker users wishing to port their games into D.

| Sub-package | Description |
|-------------|-------------|
|`de-gml:core`| Core functionality. Depends on `ichor`. |
|`de-gml:sdl` | For windowing and input. Depends on `bindbc-sdl`. |
|`de-gml:bgfx`| For drawing. Depends on `bindbc-bgfx`, `shelper`, `de-gml:sdl`. |

The library mainly focuses on helping convert GameMaker games without custom rendering setups. If you're familiar with custom rendering in GameMaker, you might be able to write your own rendering code using [bgfx](https://github.com/bkaradzic/bgfx/)'s [D bindings](https://github.com/BindBC/bindbc-bgfx).

Check the examples to see how to get started. Documentation for parts of the API that are from GML is sparse. Up-to-date documentation for GameMaker is located [here](https://manual.gamemaker.io).

GML features that can easily be converted to using D features or Phobos functions are not necessarily included in De-GML. Some simple conversions are listed in the [Conversion Cheatsheet](#conversion-cheatsheet) below.

| Table of Contents |
|-------------------|
|[API Differences](#api-differences)|
|[Conversion Cheatsheet](#conversion-cheatsheet)|

## API Differences

### General Rules
Function names and parameters are converted to [D Style](https://dlang.org/dstyle.html#naming_conventions) camelCase, but there are aliases to the GML-style snake_cased function names for convenience.

GML is a dynamically typed language, where D is statically typed. De-GML's API reflects this difference in various areas, including but not limited to:
- Conversion from floating point types to integer types is delegated to the caller (i.e. you) rather than performed implicitly by functions.
- Functions that would conditionally return `undefined` or return one of many types types may instead use [`Variant`][VariantDocs] (e.g. all DS functions do this), or they may use some other workaround.

Any enumerated constants (e.g. `pt_linestrip`, `bm_inv_src_colour`) are converted to D enums with the [appropriate casing](https://dlang.org/dstyle.html#naming_enum_members) (e.g. `PT.lineStrip`, `BM.invSrcColour`) with GML-style aliases for convenience (e.g. `pt.linestrip`, `bm.inv_src_colour`)

### Data Structures

[VariantDocs]: https://dlang.org/phobos/std_variant.html#.Variant "Documentation for Variants"

Data structure accessors have the symbol prefix removed. For example:
```d
auto a = myList[27];      //in GML: myList[| 27]
auto b = myMap["hello!"]; //in GML: myMap[? "hello"]
auto c = myGrid[12, 34];  //in GML: myGrid[# 12, 34]
```

Data structures use [`Variant`][VariantDocs] so that they can store arbitrary types. Whenever you retrieve a value from a data structure, it will be of type [`Variant`][VariantDocs]. You can get the original value back in a few ways:

- [`.peek(Type)()`](https://dlang.org/phobos/std_variant.html#.VariantN.peek): Returns a pointer to the value, or `null` if the [`Variant`][VariantDocs] doesn't contain a value of that type. Example:
```d
int* x = myList[0].peek!int();
if(x !is null){ //make sure `list[0]` was storing an `int`
	return *x; //de-reference the pointer if it's valid
}
```
- [`.get(Type)()`](https://dlang.org/phobos/std_variant.html#.VariantN.get): Tries to implicitly convert the value to the requested type. Throws an exception if the type in the [`Variant`][VariantDocs] can't be implicitly converted. Example:
```d
try{
	int x = myList[0].get!int();
}catch(VariantException ex){
	//this will run if the value couldn't be implicitly converted to an `int`
	//for example, if the value was a `string`, `double`, or `long`
}
```
- [`.coerce(Type)()`](https://dlang.org/phobos/std_variant.html#.VariantN.coerce): Tries to explicitly convert (i.e. cast) the value to the requested type. Throws an exception if the type in the [`Variant`][VariantDocs] can't be explicitly converted. Example:
```d
try{
	int x = myList[0].coerce!int();
}catch(VariantException ex){
	//this will run if the value couldn't be explicitly converted to an `int`
	//for example, if the value was a `string`
}
```
- [`visit(Handlers...)()`](https://dlang.org/phobos/std_variant.html#.visit)
- [`tryVisit(Handlers...)()`](https://dlang.org/phobos/std_variant.html#.tryVisit)

### Rooms
Room Assets are pointers in De-GML, so instead of checking if they are `== -1`, you should check if they are `is null`.

### Sprites
Sprite Assets are pointers in De-GML, so instead of checking if they are `== -1`, you should check if they are `is null`.

## Conversion Cheatsheet

### Variable Functions
> [!NOTE]
> The conversions under this header only work at compile-time. These are best used in template functions, possibly in combination with CTFE-able functions.

`var b = variable_instance_exists(id, "shields");`
```d
import std.traits;
bool b = hasMember!(typeof(id), "shields");
```

`var a = variable_instance_get_names(instance_id);`
```d
import std.traits;
string[] a = [FieldNameTuple!(typeof(instanceID))];
```

`var r = variable_instance_names_count(instance_id);`
```d
import std.traits;
size_t z = FieldNameTuple!(typeof(instanceID)).length;
```

`var x = variable_instance_get(id, "shields");`
```d
auto x = mixin("id." ~ "shields");
```

`variable_instance_set(id, "shields", 0);`
```d
mixin("id." ~ "shields" ~ " = " ~ "0");
```

#### Info Functions
`var s = nameof(name)`
```d
string s = __traits(identifier, name);
```

`var s = typeof(variable)`
```d
import std.conv;
string s = typeof(variable).to!string();
```

#### Data Type Functions
`var b = is_string(n);`
```d
bool b = is(typeof(n) == string);
```

`var b = is_real(n);`
```d
bool b = __traits(isFloating, n) || is(typeof(n) == int);
```

`var b = is_numeric(n);`
```d
bool b = __traits(isArithmetic, n);
```

`var b = is_bool(n);`
```d
bool b = is(typeof(n) == bool);
```

`var b = is_array(n);`
```d
import std.traits;
bool b = isDynamicArray!(typeof(n)) || __traits(isStaticArray, n);
```

`var b = is_struct(n);`
```d
bool b = is(typeof(n) == struct);
```

`var b = is_callable(n);`
```d
import std.traits;
bool b = isCallable!n;
```

`var b = is_ptr(n);`
```d
import std.traits;
bool b = isPointer!n;
```

`var b = is_int32(n);`
```d
bool b = is(typeof(n) == int);
```

`var b = is_int64(n);`
```d
bool b = is(typeof(n) == long);
```

`var b = is_undefined(n);`
```d
bool b = n is null; //NOTE: only works for reference-types. Value types cannot have no value in D.
```

`var b = is_nan(n);`
```d
import std.math.traits;
bool b = isNaN(n);
```

`var b = is_infinity(n);`
```d
import std.math.traits;
bool b = isInfinity(n);
```

`var b = bool(n);`
```d
bool b = cast(bool)n;
```

`var p = ptr(n);`
```d
void* p = cast(void*)n;
```

`var p = ref_create(self, "text");`
```d
typeof(n)* p = &text;
```
`var p = ref_create(self, "array", 2);`
```d
typeof(n)* p = &array[2];
```

`var l = int64(val);`
```d
long l = cast(long)val;
```

### Array Functions
> [!TIP]\
> For most negative indices in GML (e.g. `-1`, `-2`, `-3`) you can translate them to D when using slices by subtacting from the dollar operator. (e.g. `$-1`, `$-2`, `$-3`)

`var a = array_create(size);`
```d
auto a = new int[](size);
```
`var a = array_create(size, value);`
```d
auto a = new int[](size);
a[] = value;
```

`array_copy(dest, dest_index, src, src_index, length);`
```d
dest[dest_index..dest_index+length] = src[src_index..src_index+length];
```

`var b = array_equals(var1, var2);`
```d
bool b = var1 == var2;
``` 
`var b = var1 == var2;`
```d
bool b = var1 is var2;
```

`var v = array_get(variable, index);`
```d
auto v = variable[index];
```

`array_set(variable, index, value);`
```d
variable[index] = value;
```

`array_push(variable, value);`
```d
variable ~= value;
```
`array_push(variable, value1, value2, value3, value4);`
```d
variable ~= [value1, value2, value3, value4];
```

`var v = array_pop(array);`
```d
auto v = array[$-1];
array = array[0..$-1];
```

`var v = array_shift(array);`
```d
auto v = array[0];
array = array[1..$];
```

`array_insert(variable, index, value);`
```d
if(index >= variable.length) variable.length = index+1;
variable = variable[0..index] ~ value ~ variable[index+1..$];
```
`array_insert(variable, value1, value2, value3, value4);`
```d
if(index >= variable.length) variable.length = index+1;
variable = variable[0..index] ~ [value1, value2, value3, value4] ~ variable[index+1..$];
```

`array_delete(array, index, number);`
```d
array = array[0..index] ~ array[index+number..$];
```

`var i = array_get_index(array, value);`
```d
int i = -1;
foreach(index, item; array){
	if(item == value){
		i = index;
		break;
	}
}
```
`var i = array_get_index(array, value, -1, -infinity);`
```d
int i = -1;
foreach_reverse(index, item; array){
	if(item == value){
		i = index;
		break;
	}
}
```

`var b = array_contains(array, value);`
```d
import std.algorithm.searching;
bool b = array.canFind(value);
```

`array_sort(variable, true);`
```d
import std.algorithm.sorting;
variable.sort();
```
`array_sort(variable, false);`
```d
import std.algorithm.sorting;
variable.sort!"a > b"();
```

`array_reverse(my_array);`
```d
import std.array, std.range;
myArray = myArray.retro().array();
```

`array_shuffle(array);`
```d
import std.random;
array = array.randomShuffle();
```

`var i = array_length(array);`
```d
size_t z = array.length;
```

`array_resize(array, new_size);`
```d
array.length = newSize;
```

`var v = array_first(array);`
```d
auto v = array[0];
```

`var v = array_last(array);`
```d
auto v = array[$-1];
```

#### Advanced Array Functions
`var b = array_any(array, function(val, ind){ return val == "apple"; });`
```d
import std.algorithm,searching;
bool b = array.any!((val){
	return val == apple;
});
```

`var b = array_all(array, function(val, ind){ return val == "apple"; });`
```d
import std.algorithm,searching;
bool b = array.all!((val){
	return val == apple;
});
```

`array_foreach(array, function(element, index){ element.x = index; });`
```d
foreach(index, ref element; array){
	element.x = index;
}
```

`var v = array_reduce(array, function(previous, current, index){ return min(previous, current); });`
```d
import std.algorithm.iteration: reduce;
auto v = array.reduce!((previous, current){
	import std.algorithm.comparison: min;
	return min(previous, current);
})();
```

`var a = array_concat(array1, array2, array3);`
```d
auto a = array1 ~ array2 ~ array3;
```

`var a = array_union(array1, array2, array3);`
```d
import std.algorithm.setops;
var a = multiwayUnion(array1 ~ array2 ~ array3);
```

`var a = array_intersection(array1, array2, array3);`
```d
import std.algorithm.setopts, sorting;
auto a = setIntersection(array1.sort(), array2.sort(), array3.sort()).array();
```

`var a = array_filter(array, function(element){ return element >= 50; });`
```d
import std.algorithm.iteration;
auto a = array.filter!((element){
	return element >= 50;
})();
```

`var a = array_map(numbers, function(element, index){ return element * 2; });`
```d
import std.algorithm.iteration;
auto a = numbers.map!((element){
	return element * 2;
});
```

`var a = array_unique(array);`
```d
import std.array, std.algorithm.iteration, std.algorithm.sorting;
auto a = array.sort().uniq().array();
```

### Data Structures
TODO: Add these!

### Strings
> [!NOTE]
> GML strings are 1-indexed, but D `string`s are not. These examples assume you have done the conversion of index variables yourself.

`var s = string(value);`
```d
import std.conv;
string s = value.to!string();
```
`var s = string("Score: {0} / Health: {1}", score, health);`
```d
import std.format;
string s = format("Score: %s / Health: %s", score, health);
```

#### Character Code
`var s = ansi_char($41);`
```d
char c = cast(char)0x41;
```

`var r = real(str);`
```d
double d = str.to!double();
```

`var r = string_byte_at(str, index);`
```d
char c = str[index];
```

`var r = string_byte_length(str);`
```d
size_t z = str.length;
```

`var s = string_set_byte_at(str, index, value);`
```d
str[index] = value;
```

`var s = string_char_at(str, index);`
```d
import std.utf;
size_t byteIndex = str.toUTFindex(index);
dchar c = str.decode(byteIndex);
```

#### Searching and Information
`var r = string_length(str);`
```d
import std.utf;
size_t z = str.count();
```

`var r = string_pos(substr, str);`
```d
//NOTE: Yields a 1-based byte-index (to be used with the array index operator), not a codepoint-index.
import std.algorithm.searching;
string search = str.find(subStr);
size_t z = search ? 1 + str.length - search.length : 0;
```

`var r = string_pos_ext(substr, str, start_pos);`
```d
//NOTE: Yields a 1-based byte-index (to be used with the array index operator), not a codepoint-index.
import std.algorithm.searching, std.utf;
size_t startByteIndex = str.toUTFindex(startPos);
string search = str[startByteIndex..$].find(subStr);
size_t z = search ? 1 + str.length - search.length : 0;
```

`var b = string_starts_with(str, substr);`
```d
import std.algorithm.searching;
bool b = str.startsWith(subStr);
```

`var b = string_ends_with(str, substr);`
```d
import std.algorithm.searching;
bool b = str.endsWith(subStr);
```

`var b = string_count(substr, str);`
```d
import std.algorithm.searching;
bool b = str.count(subStr);
```

#### Manipulating Strings
`var s = string_copy(str, index, count);`
```d
string s = str[index..index+count];
```

`var s = string_delete(str, index, count);`
```d
string s = str[0..index] ~ str[index+count..$];
```

`var s = string_digits(str);`
```d
import std.algorithm.iteration, std.ascii;
string s = str.filter!isDigit();
```

`var s = string_format(val, total, dec);`
```d
import std.conv, std.format, std.string;
string s = format("%." ~ dec.to!string() ~ "f", val).rightJustify(total);
```

`var s = string_insert(substr, str, index);`
```d
string s = str[index] ~ subStr ~ str[index+1..$];
```

`var s = string_letters(str);`
```d
import std.algorithm.iteration, std.ascii;
string s = str.filter!isAlpha();
```

`var s = string_lettersdigits(str);`
```d
import std.algorithm.iteration, std.ascii;
string s = str.filter!isAlphaNum();
```

`var s = string_lower(str);`
```d
import std.ascii;
string s = str.toLower();
```

`var s = string_repeat(str, count);`
```d
import std.array, std.range;
string s = str.repeat(count).join();
```

`var s = string_replace(str, substr, newstr);`
```d
import std.array;
string s = str.replaceFirst(subStr, newStr);
```

`var s = string_replace_all(str, substr, newstr);`
```d
import std.array;
string s = str.replace(subStr, newStr);
```

`var s = string_upper(str);`
```d
import std.ascii;
string s = str.toUpper();
```

`var s = string_trim(str, ["|" "."]);`
```d
import std.string;
string s = str.strip("|.");
```

`var s = string_trim_start(str, ["|" "."]);`
```d
import std.string;
string s = str.stripLeft("|.");
```

`var s = string_trim_end(str, ["|" "."]);`
```d
import std.string;
string s = str.stripRight("|.");
```

`var a = string_split(string, delimiter);`
```d
import std.array;
string[] a = str.split("|");
```
`var a = string_split(string, delimiter, true);`
```d
import std.array, std.algorithm.iteration;
string[] a = str.split("|").filter!"a.length > 0"();
```

`var s = string_join(delimiter, value1, value2, value3);`
```d
import std.array, std.algorithm.iteration;
//NOTE: Does not convert the values to strings in case they are not strings already.
dstring s = [value1, value2, value3].joiner(delimiter).array();
```

`var s = string_join_ext(delimiter, values_array);`
```d
import std.array, std.algorithm.iteration;
dstring s = valuesArray.joiner(delimiter).array();
```

`var s = string_concat(value1, value2, value3);`
```d
string s = text(value1, value2, value3);
```

#### Iteration
`var s = string_foreach(str, function(character, position){ show_debug_message(character); });`
```d
import std.stdio;
foreach(position, character; str){
	writeln(character);
}
```

### Maths And Numbers

#### Date And Time


#### Number Functions

##### Rounding and Truncating
`val r = round(n);`
```d
import std.math;
double d = round(n);
```

`val r = abs(n);`
```d
import std.math;
double d = abs(n);
```

`val r = sign(n);`
```d
import std.math;
double d = sign(n);
```

`val r = floor(n);`
```d
import std.math;
double d = floor(n);
```

`val r = ceil(n);`
```d
import std.math;
double d = ceil(n);
```

`val r = min(val1, val2, val3);`
```d
import std.algorithm.comparison;
double d = min(val1, val2, val3);
```

`val r = max(val1, val2, val3);`
```d
import std.algorithm.comparison;
double d = max(val1, val2, val3);
```

`val r = mean(val1, val2, val3);`
```d
import std.algorithm.iteration;
double d = mean(val1, val2, val3);
```

`val r = clamp(val, minVal, maxVal);`
```d
import std.algorithm.comparison;
double d = clamp(val, minVal, maxVal);
```

##### Mathematical Functions
`val r = exp(n);`
```d
import std.math;
double d = exp(n);
```

`val r = ln(n);`
```d
import std.math;
double d = log(n);
```

`val r = power(x, n);`
```d
double d = x ^^ n;
```

```

`val r = sqrt(n);`
```d
import std.math;
double d = sqrt(n);
```

`val r = log2(n);`
```d
import std.math;
double d = log2(n);
```

`val r = log10(n);`
```d
import std.math;
double d = log10(n);
```

#### Angles And Distance
`val r = arccos(n);`
```d
import std.math;
double d = acos(n);
```

`val r = arcsin(n);`
```d
import std.math;
double d = asin(n);
```

`val r = arctan(n);`
```d
import std.math;
double d = atan(n);
```

`val r = arctan2(n);`
```d
import std.math;
double d = atan2(n);
```

`val r = cos(n);`
```d
import std.math;
double d = cos(n);
```

`val r = sin(n);`
```d
import std.math;
double d = sin(n);
```

`val r = tan(n);`
```d
import std.math;
double d = tan(n);
```

