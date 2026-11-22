// REQUIRES: rustup
// A successful expansion must not write to the build output.
// RUN: %build_cfip_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: %rustc_cfip --crate-type=rlib %s -o %t/lib.rlib 2>&1 | count 0

#[cfip::harden_vars_fn(var)]
pub fn value(a: i32) -> i32 {
    let var: i32 = a;
    var + 1
}
