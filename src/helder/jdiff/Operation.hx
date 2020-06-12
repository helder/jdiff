package helder.jdiff;

import haxe.DynamicAccess;
import tink.core.Any;
import helder.jdiff.JsonPointer;

@:enum
private abstract OperationName(String) from String to String {
	var Add = 'add';
	var Remove = 'remove';
	var Replace = 'replace';
	var Move = 'move';
	var Copy = 'copy';
	var Test = 'test';
}

typedef OperationData = {
	op: OperationName,
	path: JsonPointer
}

typedef FromOperation = {
	>OperationData,
	from: JsonPointer
}

typedef ValueOperation = {
	>OperationData,
	value: Dynamic
}

@:forward
abstract OperationRep<T: OperationData>(T) from T to T {
	
	inline function new(data: T)
		this = data;
		
	public function apply(input: JsonValue): JsonValue
		switch (this: OperationRep<OperationData>).get() {
			case Add(path, value):
				switch path.find(input) {
					case Document(_):
						return value.clone();
					case ArrayValue(parent, index):
						if (index > parent.length)
							throw 'Target of add outside of array bounds';
						parent.insert(index, value.clone());
					case ArrayAppendValue(parent):
						parent.push(value.clone());
					case ObjectValue(object, key):
						object[key] = value.clone();
					case NotFound:
						throw 'Path does not exist: '+path;
				}
				return input;
			case Remove(path):
				switch path.find(input) {
					case Document(_):
						return null;
					case ArrayValue(parent, index):
						parent.splice(index, 1);
					case ArrayAppendValue(parent):
						throw 'Invalid array index: -';
					case ObjectValue(object, key):
						object.remove(key);
					case NotFound:
						throw 'Path does not exist: '+path;
				}
				return input;
			case Replace(path, value):
				switch path.find(input) {
					case Document(_):
						return value.clone();
					case ArrayValue(parent, index):
						parent[index] = value.clone();
					case ArrayAppendValue(parent):
						throw 'Invalid array index: -';
					case ObjectValue(object, key):
						object[key] = value.clone();
					case NotFound:
						throw 'Path does not exist: '+path;
				}
				return input;
			case Move(from, path):
				switch from.find(input).get() {
					case Success(value):
						return ([
							Remove(from),
							Add(path, value)
						]: JsonPatch).apply(input);
					case Failure(_):
						throw 'Path does not exist: '+path;
				}
			case Copy(from, path):
				switch from.find(input).get() {
					case Success(value):
						return ([
							Add(path, value.clone())
						]: JsonPatch).apply(input);
					case Failure(_):
						throw 'Path does not exist: '+path;
				}
			case Test(path, value):
				switch path.find(input).get() {
					case Success(original):
						if (!original.equals(value))
							throw 'Test failed: '+this;
						return input;
					case Failure(_):
						throw 'Path does not exist: '+path;
				}
		}
		
	public function inverse(?prev: OperationRep<ValueOperation>): JsonPatch
		return switch (this: OperationRep<OperationData>).get() {
			case Add(path, value):
				[Test(path, value), Remove(path)];
			case Remove(path):
				[Add(prev.path, prev.value)];
			case Replace(path, value):
				[Test(prev.path, value), Replace(prev.path, prev.value)];
			case Move(from, path):
				[Move(from, path)];
			case Copy(from, path):
				throw 'Cannot invert copy operation';
			case Test(path, value):
				[Test(path, value)];
		}
		
	@:from inline static function fromFrom(data: FromOperation)
		return new OperationRep<FromOperation>(data);
		
	@:from inline static function fromValue(data: ValueOperation)
		return new OperationRep<ValueOperation>(data);
		
	@:from inline static function fromOperation<T: OperationData>(operation: Operation<T>): OperationRep<T>
		return switch operation {
			case Add(path, value):
				new OperationRep<ValueOperation>({op: OperationName.Add, path: path, value: value});
			case Remove(path):
				new OperationRep<OperationData>({op: OperationName.Remove, path: path});
			case Replace(path, value):
				new OperationRep<ValueOperation>({op: OperationName.Replace, path: path, value: value});
			case Move(from, path):
				new OperationRep<FromOperation>({op: OperationName.Move, from: from, path: path});
			case Copy(from, path):
				new OperationRep<FromOperation>({op: OperationName.Copy, from: from, path: path});
			case Test(path, value):
				new OperationRep<ValueOperation>({op: OperationName.Test, path: path, value: value});
		}
		
	@:to public inline function get(): Operation<T>
		return cast switch this.op {
			case Add: Add(this.path, expectProperty('value'));
			case Remove: Remove(this.path);
			case Replace: Replace(this.path, expectProperty('value'));
			case Move: Move(expectProperty('from'), this.path);
			case Copy: Copy(expectProperty('from'), this.path);
			case Test: Test(this.path, expectProperty('value'));
			default:
				throw 'Unsupported operation: '+this.op;
		}
		
	function expectProperty(name: String): Any {
		var obj: DynamicAccess<Any> = cast this;
		if (!obj.exists(name))
			throw 'Missing property: '+name;
		else
			return obj[name];
	}
}

enum Operation<D: OperationData> {
	
	/**
	 * The "add" operation performs one of the following functions,
	 * depending upon what the target location references:
	 * 
	 * - If the target location specifies an array index, a new value is
	 *   inserted into the array at the specified index.
	 * 
	 * - If the target location specifies an object member that does not
     *   already exist, a new member is added to the object.
	 * 
	 * - If the target location specifies an object member that does exist,
     *   that member's value is replaced.
	 */
	Add(path: JsonPointer, value: JsonValue): Operation<ValueOperation>;
	
	/**
	 * The "remove" operation removes the value at the target location.
	 */
	Remove(path: JsonPointer): Operation<OperationData>;
	
	/**
	 * The "replace" operation replaces the value at the target 
	 * location with a new value.
	 */
	Replace(path: JsonPointer, value: JsonValue): Operation<ValueOperation>;
	
	/**
	 * The "move" operation removes the value at a specified location 
	 * and adds it to the target location.
	 */
	Move(from: JsonPointer, path: JsonPointer): Operation<FromOperation>;
	
	/**
	 * The "copy" operation copies the value at a specified location 
	 * to the target location.
	 */
	Copy(from: JsonPointer, path: JsonPointer): Operation<FromOperation>;
	
	/**
	 * The "test" operation tests that a value at the target location 
	 * is equal to a specified value.
	 */
	Test(path: JsonPointer, value: JsonValue): Operation<ValueOperation>;
	
}