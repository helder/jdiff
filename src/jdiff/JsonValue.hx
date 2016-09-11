package jdiff;

import haxe.DynamicAccess;

using tink.CoreApi;

@:enum
abstract Primitive(Int) {
	var PNumber = 1;
	var PString = 2;
	var PBoolean = 3;
	var PNull = 4;
}

abstract JsonValue(Dynamic) from Dynamic {
	
	public inline function isArray()
		return Std.is(this, Array);
		
	public inline function isObject()
		return 
			!Std.is(this, String) &&
			!Std.is(this, Array) &&
			!Std.is(this, Int) &&
			!Std.is(this, Float) &&
			!Std.is(this, Bool) &&
			Reflect.isObject(this);
		
	public inline function primitiveType() {
		return 
			if (this == null) PNull
			else if (Std.is(this, String)) PString
			else if (Std.is(this, Bool)) PBoolean
			else if (Std.is(this, Int) || Std.is(this, Float)) PNumber
			else null;
	}
			
	public function clone(): JsonValue {
		var current: JsonValue = this;
		if (current.isArray())
			return cloneArray(current);
		if(current == null || !current.isObject())
			return current;
		return cloneObject(current);
	}

	function cloneArray(array: Array<JsonValue>): JsonValue
		return [for (i in array) i.clone()];

	function cloneObject(obj: DynamicAccess<JsonValue>): JsonValue {
		var response: DynamicAccess<JsonValue> = new DynamicAccess();

		for (key in obj.keys())
			response[key] = obj[key].clone();

		return response;
	}
	
	public function equals(value: JsonValue): Bool {
		var current: JsonValue = this;
		if (current.isArray() && value.isArray())
			return equalArrays(current, value);
		if (current.isObject() && value.isObject())
			return equalObjects(current, value);
		return current == value && current.primitiveType() == value.primitiveType();
	}
	
	function equalArrays(a: Array<JsonValue>, b: Array<JsonValue>) {
		if (a.length != b.length) 
			return false;
		for (i in 0 ... a.length)
			if (!a[i].equals(b[i])) 
				return false;
		return true;
	}
	
	function equalObjects(a: DynamicAccess<JsonValue>, b: DynamicAccess<JsonValue>) {
		var keysA = a.keys(), keysB = b.keys();
		if (keysA.length != keysB.length)
			return false;
		for (key in keysA)
			if (!a[key].equals(b[key])) 
				return false;
		return true;
	}
	
	@:to 
	inline function promote<T>(): T 
		return this;
		
	@:from 
	inline static function fromDynamicAccess(obj: DynamicAccess<JsonValue>): JsonValue
		return cast obj;
		
}