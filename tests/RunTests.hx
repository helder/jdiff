import buddy.Buddy;

@colorize
class RunTests implements Buddy<[
    PatchTest,
	InverseTest
]> {
	public static function __init__() {
		#if php untyped __call__('ini_set', 'xdebug.max_nesting_level', 10000); #end
	}
}