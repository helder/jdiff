package jdiff;

import haxe.DynamicAccess;

abstract JsonValue(Dynamic) from Dynamic to Dynamic {
	
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
	
	@:to public inline function toDynamicAccess(): DynamicAccess<JsonValue>
		return cast this;
		
}