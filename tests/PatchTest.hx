import buddy.BuddySuite;
import haxe.Json;
import helder.JDiff;

using buddy.Should;

class PatchTest extends BuddySuite {

	public function new() {		
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