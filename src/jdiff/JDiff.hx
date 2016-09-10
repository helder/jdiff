package jdiff;

class JDiff {
	
	public static function diff(a: JsonValue, b: JsonValue) {
		var a = [
			{ name: 'a' },
			{ name: 'b' },
			{ name: 'c' }
		];
		var patch: Patch = [
			{"op":"add","path":"/3","value":{"name":"d"}},
			{"op":"remove","path":"/1"}
		];
		for (p in patch) 
			trace(p.path.find(a));
		/*switch p.get() {
			case Add(path, _): 
				trace(path.find(a));
			default:
		}*/
	}
	
}