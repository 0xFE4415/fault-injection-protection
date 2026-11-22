// REQUIRES: rustup
// The macro must find a requested let inside the initializer of another let.
// RUN: %build_cfip_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: %rustc_cfip --crate-type=rlib --emit=llvm-ir %s -o %t/lib.ll
// RUN: FileCheck %s < %t/lib.ll
// CHECK-COUNT-2: call {{.*}}@cfip_harden_var_

#[cfip::harden_vars_fn(var)]
#[unsafe(no_mangle)]
pub fn in_block(a: i32) -> i32 {
    let result: i32 = {
        let var: i32 = a;
        var + 1
    };
    result
}

#[cfip::harden_vars_fn(var)]
#[unsafe(no_mangle)]
pub fn in_closure(a: i32) -> i32 {
    let add_one = |x: i32| {
        let var: i32 = x;
        var + 1
    };
    add_one(a)
}
