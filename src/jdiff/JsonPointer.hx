package jdiff;

import haxe.DynamicAccess;
using tink.CoreApi;

enum SegmentResult {
	Failed;
	Continue;
}

enum TargetResult {
	Value(value: Any);
	ArrayValue(parent: Array<Any>, index: Int);
	ObjectValue(object: DynamicAccess<Any>, key: String);
	NotFound;
}

abstract PointerTarget(TargetResult) from TargetResult to TargetResult {
	
	public inline function get(): Outcome<Any, Noise>
		return switch this {
			case Value(value): 
				Success(value);
			case ArrayValue(parent, index):
				Success(parent[index]);
			case ObjectValue(object, key):
				Success(object[key]);
			case NotFound:
				Failure(Noise);
		}
		
}

/**
 * JSON Pointer defines a string syntax for identifying a specific value
 * within a JavaScript Object Notation (JSON) document.
 */
abstract JsonPointer(String) from String to String {
	
	static var separator = '/';
	static var separatorEReg: Lazy<EReg> = ~/\//g;
	static var encodedSeparator = '~1';
	static var encodedSeparatorEReg: Lazy<EReg> = ~/~1/g;

	static var escapeChar = '~';
	static var escapeEReg: Lazy<EReg> = ~/~/g;
	static var encodedEscape = '~0';
	static var encodedEscapeEReg: Lazy<EReg> = ~/~0/g;
	
	static var parseEReg: Lazy<EReg> = ~/\/|~1|~0/g;
	static var arrayIndexEReg: Lazy<EReg> = ~/^(0|[1-9]\d*)$/;
	
	public function find(input: Any): PointerTarget {
		if (this == null)
			throw 'Invalid JsonPointer: null';
		
		if (this == '')
			return Value(input);
		
		if (this == separator)
			return ObjectValue(input, '');
		
		var target: PointerTarget;
		
		parse(function(segment) {
			if (input == null) {
				target = NotFound;
				return Failed;
			}

			if (Std.is(input, Array)) // todo: context stuff				
				target = ArrayValue(input, parseArrayIndex(segment));
			else
				target = ObjectValue(input, segment);
			
			input = target.get();
			
			return Continue;
		});
		
		return target;
	}
	
	function parseArrayIndex (s: String): Int
		if(arrayIndexEReg.get().match(s))
			return Std.parseInt(s);
		else
			throw 'Invalid array index: ' + s;
	
	function parse(onSegment: String -> SegmentResult) {
		var pos, accum, match, matcher: EReg = parseEReg.get();

		pos = this.charAt(0) == separator ? 1 : 0;
		accum = '';

		while(matcher.match(this.substr(pos))) {

			match = matcher.matched(0);
			var matchedPos = matcher.matchedPos().pos;
			accum += this.substring(pos, matchedPos);
			pos = matchedPos + match.length;

			if(match == separator)
				switch onSegment(accum) {
					case Failed: return;
					default: accum = '';
				}
			else
				accum += match == encodedSeparator ? separator : escapeChar;
			
		}

		accum += this.substr(pos);
		onSegment(accum);
	}
	
}