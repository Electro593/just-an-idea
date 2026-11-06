test_types :: () {
	info: *Type_Info_Struct = xx type_info(
		// #type struct (value: int = 2 @foo , T: Type @bar ) {
		// 	A :: value;
		// 	B: int = A;
		// 	C: T;
		// } (T = float)
		#type union (value: int = 2 @foo , T: Type @bar , Y: $X = void ) kind: int {
			A :: value;
			B: int = A;
			C: T;
			2 ,, x := struct { a: int; }.{ a = 2 };
		} (T = float)
	);

	print("\n%\n\n", info.*);
	print("%\n", info.polymorph_source_struct.*);
}

main :: () {
	print("%\n", !"");
	// connection: Connection;
	// get_linked_ranges(*connection, 0, "", 0, 0, .DEFINITION);
}

#import "Basic";
