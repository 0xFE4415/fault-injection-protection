// REQUIRES: rustup
// Macro errors must be compile errors at the offending name, not panics.
// RUN: %build_cfip_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: not %rustc_cfip --crate-type=rlib --cfg missing %s -o %t/lib.rlib 2>&1 | FileCheck %s --check-prefix=MISSING
// RUN: not %rustc_cfip --crate-type=rlib --cfg uninit %s -o %t/lib.rlib 2>&1 | FileCheck %s --check-prefix=UNINIT
// RUN: not %rustc_cfip --crate-type=rlib --cfg duplicate %s -o %t/lib.rlib 2>&1 | FileCheck %s --check-prefix=DUPLICATE
// MISSING-NOT: panicked
// MISSING: error: no `let first: Type = value;` found for `first`
// MISSING-NEXT: harden_vars_fn_errors.rs:[[@LINE+8]]:24
// MISSING: error: no `let second: Type = value;` found for `second`
// MISSING-NEXT: harden_vars_fn_errors.rs:[[@LINE+6]]:31
// UNINIT-NOT: panicked
// UNINIT: error: cannot harden `var`: it has no initializer
// UNINIT-NEXT: harden_vars_fn_errors.rs:[[@LINE+12]]:9

#[cfg(missing)]
#[cfip::harden_vars_fn(first, second)]
pub fn value(a: i32) -> i32 {
    let first = a;
    first + 1
}

#[cfg(uninit)]
#[cfip::harden_vars_fn(var)]
pub fn value(a: i32) -> i32 {
    let var: i32;
    var = a;
    var + 1
}

// DUPLICATE-NOT: panicked
// DUPLICATE: error: no `let first: Type = value;` found for `first`
// DUPLICATE-NEXT: harden_vars_fn_errors.rs:[[@LINE+4]]:24
// DUPLICATE-NOT: error: no
// DUPLICATE: error: aborting due to 1 previous error
#[cfg(duplicate)]
#[cfip::harden_vars_fn(first, first)]
pub fn value(a: i32) -> i32 {
    let first = a;
    first + 1
}
