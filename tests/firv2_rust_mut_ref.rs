// REQUIRES: rustup
// The hardened function runs twice, so the macro must reject a `&mut` argument.
// RUN: %build_firv2_macro
// RUN: not %rustc_firv2 %s -o %t.out 2>&1 | FileCheck %s
// CHECK: error:
// CHECK: counter

#[rust_firv2::harden_fn(i32::eq)]
fn bump(counter: &mut i32) -> i32 {
    *counter += 1;
    *counter
}

fn main() {
    let mut counter = 0;
    println!("{}", bump(&mut counter));
}
