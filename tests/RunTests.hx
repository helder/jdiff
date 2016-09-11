import haxe.Json;
import jdiff.JDiff;
import buddy.SingleSuite;

using buddy.Should;

@colorize
class RunTests extends SingleSuite {

	public function new() {
		#if php untyped __call__('ini_set', 'xdebug.max_nesting_level', 10000); #end
		
		describe('jdiff', 
			for (suite in PatchTests.tests)
				for (test in suite)
					if (test.disabled == null || !test.disabled)
						it(test.comment == null ? 'no comment' : test.comment, 
							if (test.expected != null)
								test.patch.apply(test.doc).equals(test.expected).should.be(true)
							else if (test.error != null)
								test.patch.apply.bind(test.doc).should.throwType(String)
						)
		);
		
	}
  
}