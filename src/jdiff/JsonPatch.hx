package jdiff;

import jdiff.Operation;

typedef Operations = Array<OperationRep<OperationData>>;

@:forward
@:access(jdiff.Operation.OperationName)
abstract JsonPatch(Operations) from Operations to Operations {
	
	public function apply(input: JsonValue): JsonValue {
		var output = input.clone();
		for (operation in this)
			output = operation.apply(output);
		return output;
	}
	
	public function inverse(): JsonPatch {
		var result: JsonPatch = [];
		var i = this.length;
		while (i-- > 0) {
			var operation = this[i];
			switch operation.op {
				case Replace | Remove:
					if (i == 0)
						throw 'This operation cannot be inverted without a test operation: '+operation;
					var test = this[--i];
					if (test.op != Test)
						throw 'This operation cannot be inverted without a test operation: '+operation;
					result = result.concat(operation.inverse(cast test));
				case Copy:
					throw 'Cannot invert: '+operation;
				default:
					result = result.concat(operation.inverse());
			}
		}
		return result;
	}
	
	@:from inline static function fromOperations(a: Array<Operation>): JsonPatch
		return [for (i in a) (i: OperationRep<OperationData>)];
	
}