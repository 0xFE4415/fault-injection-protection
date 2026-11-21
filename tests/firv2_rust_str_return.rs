// REQUIRES: rustup
// A fat-pointer return gives an eq function with four parameters; the link must not crash.
// RUN: %build_firv2_macro
// RUN: %rustc_firv2 %s -o %t.out
// RUN: %t.out | FileCheck %s
// CHECK: firv2

fn same<T: PartialEq + ?Sized>(left: &T, right: &T) -> bool {
    left == right
}

#[rust_firv2::harden_fn(same)]
fn name() -> &'static str {
    "firv2"
}

fn main() {
    println!("{}", name());
}
