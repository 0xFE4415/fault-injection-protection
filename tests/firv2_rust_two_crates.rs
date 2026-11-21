// REQUIRES: rustup
// Each crate restarts the macro counter, so generated symbols must not collide across crates.
// RUN: %build_firv2_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: %rustc_firv2 --crate-type=rlib --crate-name firv2_lib --cfg firv2_lib %s -o %t/libfirv2_lib.rlib
// RUN: %rustc_firv2 --extern firv2_lib=%t/libfirv2_lib.rlib %s -o %t/out
// RUN: %t/out | FileCheck %s
// CHECK: 12

#[cfg(firv2_lib)]
#[rust_firv2::harden_fn(i32::eq)]
pub fn lib_value() -> i32 {
    7
}

#[cfg(not(firv2_lib))]
#[rust_firv2::harden_fn(i32::eq)]
fn bin_value() -> i32 {
    5
}

#[cfg(not(firv2_lib))]
fn main() {
    println!("{}", firv2_lib::lib_value() + bin_value());
}
