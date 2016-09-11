package jdiff;

@:enum
abstract LcsOperation(Int) {
	var Remove = -1;
	var Equal = 0;
	var Add = 1;
}

typedef Matrix = Array<Array<{value: Int, type: LcsOperation}>>;
typedef Reducer<T> = T -> LcsOperation -> Int -> Int -> T;

class Lcs {
	
	var prefix: Int;
	var matrix: Matrix;
	var suffix: Int;

	public function new(a: Array<String>, b: Array<String>) {
		var cols = a.length;
		var rows = b.length;

		prefix = findPrefix(a, b);
		suffix = prefix < cols && prefix < rows
			? findSuffix(a, b)
			: 0;

		var remove = suffix + prefix - 1;
		cols -= remove;
		rows -= remove;
		matrix = createMatrix(cols, rows);
		
		var j = cols - 1;
		while (j >= 0) {
			var i = rows - 1;
			while (i >= 0) {
				matrix[i][j] = backtrack(matrix, a, b, prefix, j, i);
				--i;
			}
			--j;
		}
	}
	
	function findPrefix(a: Array<String>, b: Array<String>) {
		var i = 0;
		var l = Math.min(a.length, b.length);
		while(i < l && a[i] == b[i])
			++i;
		return i;
	}
	
	function findSuffix(a: Array<String>, b: Array<String>) {
		var al = a.length - 1;
		var bl = b.length - 1;
		var l = Math.min(al, bl);
		var i = 0;
		while(i < l && a[al-i] == b[bl-i])
			++i;
		return i;
	}
	
	function createMatrix (cols: Int, rows: Int): Matrix {
		var m = [], i, j, lastrow;

		lastrow = m[rows] = [];
		for (j in 0 ... cols)
			lastrow[j] = {value: cols - j, type: Remove};

		for (i in 0 ... rows) {
			m[i] = [];
			m[i][cols] = {value: rows - i, type: Add};
		}

		m[rows][cols] = {value: 0, type: Equal};

		return m;
	}
	
	function backtrack(matrix: Matrix, a: Array<String>, b: Array<String>, start: Int, j: Int, i: Int) {
		if (a[j+start] == b[i+start]) 
			return {value: matrix[i + 1][j + 1].value, type: Equal};
			
		if (matrix[i][j + 1].value < matrix[i + 1][j].value)
			return {value: matrix[i][j + 1].value + 1, type: Remove};

		return {value: matrix[i + 1][j].value + 1, type: Add};
	}

	public function reduce<T>(reducer: Reducer<T>, initial: T): T {
		var i, j, k, op, r = initial;

		var m = matrix;

		for(i in 0 ... prefix)
			r = reducer(r, Equal, i, i);

		k = prefix > 0 ? prefix - 1 : 0;
		i = 0;
		j = 0;
		while(i < m.length) {
			op = m[i][j].type;
			r = reducer(r, op, i+k, j+k);

			switch op {
				case Equal:  
					++i; ++j;
				case Remove: 
					++j;
				case Add:  
					++i;
			}
		}

		i += k;
		j += k;
		for(k in 0 ... suffix)
			r = reducer(r, Equal, i+k, j+k);

		return r;
	}
	
}