package jdiff;

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
abstract OperationRep<T: OperationData>(T) from OperationData to OperationData {
	
	inline function new (data: T)
		this = data;
		
	@:from inline static function fromFrom(data: FromOperation)
		return new OperationRep(data);
		
	@:from inline static function fromValue(data: ValueOperation)
		return new OperationRep(data);
		
	@:from inline static function fromOperation(operation: Operation): OperationRep<OperationData>
		return switch operation {
			case Add(path, value):
				{op: OperationName.Add, path: path, value: value};
			case Remove(path):
				{op: OperationName.Remove, path: path};
			case Replace(path, value):
				{op: OperationName.Replace, path: path, value: value};
			case Move(from, path):
				{op: OperationName.Move, from: from, path: path};
			case Copy(from, path):
				{op: OperationName.Copy, from: from, path: path};
			case Test(path, value):
				{op: OperationName.Test, path: path, value: value};
		}
		
	@:to public inline function get(): Operation
		return switch this.op {
			case Add: Add(this.path, (cast this).value);
			case Remove: Remove(this.path);
			case Replace: Replace(this.path, (cast this).value);
			case Move: Move((cast this).from, this.path);
			case Copy: Copy((cast this).from, this.path);
			case Test: Test(this.path, (cast this).value);
			default:
				throw 'Unsupported operation: '+this.op;
		}
}

enum Operation {
	
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
	Add(path: JsonPointer, value: JsonValue);
	
	/**
	 * The "remove" operation removes the value at the target location.
	 */
	Remove(path: JsonPointer);
	
	/**
	 * The "replace" operation replaces the value at the target 
	 * location with a new value.
	 */
	Replace(path: JsonPointer, value: JsonValue);
	
	/**
	 * The "move" operation removes the value at a specified location 
	 * and adds it to the target location.
	 */
	Move(from: JsonPointer, path: JsonPointer);
	
	/**
	 * The "copy" operation copies the value at a specified location 
	 * to the target location.
	 */
	Copy(from: JsonPointer, path: JsonPointer);
	
	/**
	 * The "test" operation tests that a value at the target location 
	 * is equal to a specified value.
	 */
	Test(path: JsonPointer, value: JsonValue);
	
}