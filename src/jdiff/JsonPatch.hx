package jdiff;

import jdiff.Operation;

typedef Operations = Array<OperationRep<OperationData>>;

@:forward
abstract JsonPatch(Operations) from Operations to Operations {
	
	public function apply(input: JsonValue): JsonValue {
		var output = input.clone();
		for (operation in this)
			output = operation.apply(output);
		return output;
	}
	
}