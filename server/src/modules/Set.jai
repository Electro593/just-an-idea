// If target is in array, binary_search returns true, the found elem, and index.
// Otherwise, binary_search returns false, undefined, and the potential insert position for target.
// E.g., 0 if target is less than array[0], array.count if target is greater than array[array.count-1], etc.
binary_search :: (array: [] $T, target: $E, $$cmp: (target: E, current: T) -> $R = null) -> found: bool, elem: T, index: int {
	low := 0;
	high := array.count;

	while low < high {
		index := low + (high - low) / 2;

		#if is_constant(cmp) && cmp == null {
			if target < array[index] high = index;
			else if target > array[index] low = index + 1;
			else return true, array[index], index;
		} else {
			compare := cmp(target, array[index]);
			if compare < 0 high = index;
			else if compare > 0 low = index + 1;
			else return true, array[index], index;
		}
	}

	dummy: T = ---;
	return false, dummy, low;
}


quick_sort :: (array: [] $T, param: $P, cmp: (a: T, b: T, p: P) -> $R) {
	Entry :: struct {
		low: int;
		high: int;
	}

	if (array.count == 0) return;

	// Uses max floor(log2(n))+1
	// We add an extra 1 to be safe though.
	log2 :: #run log(2.0);
	stack_size := cast(int) (log(cast(float64) array.count) / log2) + 2;

	stack := NewArray(stack_size, Entry);
	sp := 0;

	stack[sp] = .{ 0, array.count - 1 };
	sp += 1;

	while sp > 0 {
		sp -= 1;
		using entry := stack[sp];
		if low < 0 || high < 0 || low >= high then continue;

		// Select median of three as pivot
		p1, p2, p3 := low, low + (high - low) / 2, high;
		if p1 != p2 && cmp(array[p2], array[p1], param) < 0 then p1, p2 = p2, p1;
		if p1 != p3 && cmp(array[p3], array[p1], param) < 0 then p1, p3 = p3, p1;
		if p2 != p3 && cmp(array[p2], array[p3], param) < 0 then p2, p3 = p3, p2;
		pivot := p3;

		// Partition
		i := low - 1;
		j := high + 1;
		while true {
			i += 1;
			while i != pivot && cmp(array[i], array[pivot], param) < 0
				i += 1;

			j -= 1;
			while j != pivot && cmp(array[j], array[pivot], param) > 0
				j -= 1;

			if i >= j break;

			array[i], array[j] = array[j], array[i];
		}

		if (j - low < high - (j + 1)) {
			// Upper half (larger, runs second)
			stack[sp] = .{ j + 1, high };
			// Lower half (smaller, runs first)
			stack[sp+1] = .{ low, j };
		} else {
			// Lower half (larger, runs second)
			stack[sp] = .{ low, j };
			// Upper half (smaller, runs first)
			stack[sp+1] = .{ j + 1, high };
		}
		sp += 2;
	}

	array_free(stack);
}

#scope_module

#import "Basic";
#import "Math";
