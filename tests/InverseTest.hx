import buddy.BuddySuite;
import helder.JDiff;
import helder.jdiff.JsonPatch;

using buddy.Should;

class InverseTest extends BuddySuite {
	
	var objectA = {
		a: 132,
		b: 654,
		c: ['a', 'b'],
		d: {
			a: 132
		}
	};
	var objectB = {
		a: true,
		b: 'io',
		c: ['a', 'b', 'c'],
		d: {
			a: 132,
			k: 'ok'
		},
		e: []
	}
	var arrayA = [1, 2, 3, 4, 5, 6, 7, 8];
	var arrayB = [3, 4, 5, 123, 7, 8];

	public function new() {
		describe('inverse', {
			it('for objects', {
				var patch = JDiff.diff(objectA, objectB);
				patch.inverse().apply(objectB).equals(objectA).should.be(true);
			});
			
			it('double for objects', {
				var patch = JDiff.diff(objectA, objectB);
				patch.inverse().inverse().apply(objectA).equals(objectB).should.be(true);
			});
			
			it('for arrays', {
				var patch = JDiff.diff(arrayA, arrayB);
				patch.inverse().apply(arrayB).equals(arrayA).should.be(true);
			});
			
			it('double for arrays', {
				var patch = JDiff.diff(arrayA, arrayB);
				patch.inverse().inverse().apply(arrayA).equals(arrayB).should.be(true);
			});
			
			it('should throw if not invertible', {
				var patch: JsonPatch = cast [{ op: 'remove', path: '/a' }];
				patch.inverse.bind().should.throwType(String);
				patch = cast [{ op: 'replace', path: '/a', value: 'b' }];
				patch.inverse.bind().should.throwType(String);
				patch = cast [{ op: 'copy', path: '/a', from: '/b' }];
				patch.inverse.bind().should.throwType(String);
			});
		});
	}
	
}