package jdiff;

import haxe.DynamicAccess;
using tink.CoreApi;
using StringTools;

enum SegmentResult {
	Failed;
	Continue;
}

enum TargetResult {
	Document(value: JsonValue);
	ArrayValue(parent: Array<JsonValue>, index: Int);
	ArrayAppendValue(parent: Array<JsonValue>);
	ObjectValue(object: DynamicAccess<JsonValue>, key: String);
	NotFound;
}

abstract PointerTarget(TargetResult) from TargetResult to TargetResult {
	
	public inline function get(): Outcome<JsonValue, Noise>
		return switch this {
			case Document(value): 
				Success(value);
			case ArrayValue(parent, index):
				Success(parent[index]);
			case ObjectValue(object, key):
				Success(object[key]);
			case NotFound | ArrayAppendValue(_):
				Failure(Noise);
		}
		
}

/**
 * JSON Pointer defines a string syntax for identifying a specific value
 * within a JavaScript Object Notation (JSON) document.
 */
abstract JsonPointer(String) from String to String {
	
	inline static var separator = '/';
	inline static var encodedSeparator = '~1';

	inline static var escapeChar = '~';
	inline static var encodedEscapeChar = '~0';
	
	public function find(input: JsonValue): PointerTarget {
		if (this == null)
			throw 'Invalid JsonPointer: null';
		
		if (this == '')
			return Document(input);
		
		if (this == separator)
			return ObjectValue(input, '');
		
		var target: PointerTarget = NotFound;
		
		for (segment in this.substr(1).split('/').map(decodeSegment)) {
			if (input == null)
				return NotFound;

			if (input.isArray()) // todo: context stuff			
				if (segment == '-')
					target = ArrayAppendValue(input);
				else
					target = ArrayValue(input, parseArrayIndex(segment));
			else
				target = ObjectValue(input, segment);
			
			input = switch target.get() {
				case Success(found): found;
				default: null;
			}
		}
		
		return target;
	}
	
	function parseArrayIndex (s: String): Int
		if(~/^(0|[1-9]\d*)$/.match(s))
			return Std.parseInt(s);
		else
			throw 'Invalid array index: ' + s;
	
	@:op(A + B)
	inline public function addSegment(segment: String): JsonPointer
		return this + '/' + encodeSegment(segment);
		
	@:op(A + B)
	inline public function addIndex(index: Int): JsonPointer
		return this + '/' + Std.string(index);
	
	public static function encodeSegment(s: String)
		return s.replace(separator, encodedSeparator).replace(escapeChar, encodedEscapeChar);
		
	public static function decodeSegment(s: String)
		return s.replace(encodedSeparator, separator).replace(encodedEscapeChar, escapeChar);
	
}
