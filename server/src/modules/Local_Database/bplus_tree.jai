MAX_CHILDREN :: 8;

BPlus_Tree_Node :: struct(Key_Type: Type) {
  Entry :: struct {
    child: *BPlus_Tree_Node;
    key: Key_Type;
  }
  
  entries: [MAX_CHILDREN] Entry;
  last_child: *BPlus_Tree_Node;
}

BPlus_Tree_Leaf :: struct(Key_Type: Type) {
  Entry :: struct {
    key: Key_Type;
    value: u64;
  }
  
  entries: [MAX_CHILDREN] Entry;
  next: *BPlus_Tree_Leaf;
}
