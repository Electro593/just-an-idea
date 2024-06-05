// If target is in array, binary_search returns its index and true.
// Otherwise, binary_search returns the insert position for target and false.
// E.g., 0 if target is less than array[0], array.count if target is greater than array[array.count-1], etc.
//
// compare_function should operate on target and array[index] and modify compare.
binary_search :: (array: [] $T, target: T, $compare_function: Code = null) -> int, found: bool #expand {
  low := 0;
  high := array.count;
  
  while low < high {
    index := low + (high - low) / 2;
    
    #if compare_function == null {
      if target < array[index] high = index;
      else if target > array[index] low = index + 1;
      else return index, true;
    } else {
      compare: int = ---;
      #insert,scope() compare_function;
      if compare < 0 high = index;
      else if compare > 0 low = index + 1;
      else return index, true;
    }
  }
  
  return low, false;
}