package jdiff;

import haxe.DynamicAccess;
import haxe.Json;
import jdiff.JDiff.JDiffState;
import jdiff.JsonPointer;
import jdiff.Lcs.LcsOperation in LcsOp;
import jdiff.Operation;

using tink.CoreApi;

typedef JDiffState = {
	patch: JsonPatch,
	invertible: Bool,
	hash: Any -> String
}

class JDiff {
	
	public static function diff(a: JsonValue, b: JsonValue, ?state: JDiffState): JsonPatch
		return appendChanges(a, b, '', initialState(state)).patch;
		
	static function initialState(state: JDiffState) return {
		patch: optionOr(state, 'patch', []),
		invertible: optionOr(state, 'invertible', true),
		hash: optionOr(state, 'hash', function(input) return Json.stringify(input))
	}
	
	static function optionOr<T>(obj: Any, key: String, value: T): T {
		var ref: DynamicAccess<T> = obj;
		return (ref == null || ref[key] == null) ? value : ref[key];
	}
	
	static function appendChanges(a: JsonValue, b: JsonValue, path: JsonPointer, state: JDiffState) {
		if(a.isArray() && b.isArray())
			return appendArrayChanges(a, b, path, state);

		if(a.isObject() && b.isObject())
			return appendObjectChanges(a, b, path, state);

		return appendValueChanges(a, b, path, state);
	}
	
	static function appendObjectChanges(o1: DynamicAccess<JsonValue>, o2: DynamicAccess<JsonValue>, path: JsonPointer, state: JDiffState) {
		var keys = o2.keys();
		keys.reverse();
		for (key in keys)
			if (o1.exists(key))
				appendChanges(o1[key], o2[key], path + key, state);
			else
				state.patch.push(Add(path + key, o2[key]));
		
		keys = o1.keys();
		keys.reverse();
		for (key in keys)
			if (!o2.exists(key)) {
				if (state.invertible)
					state.patch.push(Test(path + key, o1[key]));
				state.patch.push(Remove(path + key));
			}

		return state;
		
	}
	
	static function appendArrayChanges(a1: Array<Any>, a2: Array<Any>, path: JsonPointer, state: JDiffState) {
		var a1hash = a1.map(state.hash);
		var a2hash = a2.map(state.hash);

		var lcs = new Lcs(a1hash, a2hash);
		
		return lcsToJsonPatch(a1, a2, path, state, lcs);
	}
	
	static function appendValueChanges(a: JsonValue, b: JsonValue, path: JsonPointer, state: JDiffState) {
		if(a != b) {
			if(state.invertible)
				state.patch.push(Test(path, a));

			state.patch.push(Replace(path, b));
		}

		return state;
	}
	
	static function lcsToJsonPatch(a1: Array<Any>, a2: Array<Any>, path: JsonPointer, state: JDiffState, lcs: Lcs) {
		var offset = 0;
		return lcs.reduce(function(state: JDiffState, op: LcsOp, i: Int, j: Int) {
			var last;
			var patch = state.patch;
			var p = path + (j + offset);
			
			switch op {
				case LcsOp.Remove:
					last = patch[patch.length-1];

					if(state.invertible)
						patch.push(Test(p, a1[j]));

					if(last.op == Add && last.path == p)
						last.op = Replace;
					else
						patch.push(Remove(p));

					offset -= 1;
				case LcsOp.Add:
					patch.push(Add(p, a2[i]));

					offset += 1;
				case LcsOp.Equal:
					appendChanges(a1[j], a2[i], p, state);
			}
			return state;
		}, state);
	}
	
}