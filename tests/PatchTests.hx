import haxe.Json;
import haxe.Resource;
import haxe.macro.Context;
import jdiff.JsonValue;
import sys.FileSystem;
import sys.io.File;
import jdiff.JsonPatch;

typedef Test = {
	comment: String,
	doc: JsonValue,
	patch: JsonPatch,
    ?expected: JsonValue,
	?error: String,
	?disabled: Bool
}

typedef Suite = Array<Test>

class PatchTests {

	#if macro
	
	static var dir = 'tests/patch/';
	
	public static function init()
		for (file in FileSystem.readDirectory(dir))
			Context.addResource(file, File.getBytes(dir+file));
	
	#else
	
	public static var tests(default, null): Array<Suite> = [
		for (resource in Resource.listNames())
			Json.parse(Resource.getString(resource))
	];
	
	#end
	
}