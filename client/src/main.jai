// #import "Basic"; // Hello!
// H :: #import"Hash_Table"; // Hello!

// Hello!

/*
  /*
    Nested comment
  */
*/

str :: "Tab:\tLine:\nCR:\rNull:\0Hex:\x23Uni:\u1234Slash:\\Quote:\"End";

here\ _str: : #string __STR
  asbcsdx // asd
__STR;

// #run print("%\n", str);

Test_Struct :: struct {
  a: int;
  b: string;
}

Enum :: enum {
  A :: 12;
  B;
  C :: A + B;
}

main :: () {
  d := Test_Struct.{a = 1, b = "abc"};
  // print("Hello! % %\n", Enum.C, d.b);
}