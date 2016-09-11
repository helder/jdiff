import haxe.Json;
import haxe.Resource;
import jdiff.JsonValue;
import jdiff.JsonPatch;

#if macro
import sys.FileSystem;
import sys.io.File;
import haxe.macro.Context;
#end

typedef Test = {
	?comment: String,
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