import jdiff.JDiff;
import buddy.SingleSuite;

@colorize
class RunTests extends SingleSuite {

	public function new() {
		describe('jdiff', {
			it('should start', {
				JDiff.diff(1, 2);
			});
		});
	}
  
}