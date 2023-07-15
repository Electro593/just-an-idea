#import "Basic";

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
  print("Hello! % %\n", Enum.C, d.b);
}