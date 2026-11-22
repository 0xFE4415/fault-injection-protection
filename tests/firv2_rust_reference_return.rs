// REQUIRES: rustup
// A returned reference is compared through the reference, not by reading the pointer slot as the referent.
// RUN: %build_firv2_macro
// RUN: %rustc_firv2 %s -o %t.out
// RUN: %t.out | FileCheck %s
// CHECK: [1, 2, 3, 4]

static TABLE: [u64; 4] = [1, 2, 3, 4];

fn same<T: PartialEq + ?Sized>(left: &T, right: &T) -> bool {
    left == right
}

#[rust_firv2::harden_fn(same)]
fn table() -> &'static [u64; 4] {
    &TABLE
}

fn main() {
    println!("{:?}", table());
}
