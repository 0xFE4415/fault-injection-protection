// REQUIRES: rustup
// The macro takes variable names only; anything else must be a compile error instead of hardening nothing.
// RUN: %build_cfip_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: not %rustc_cfip --crate-type=rlib %s -o %t/lib.rlib 2>&1 | FileCheck %s --check-prefix=LITERAL
// RUN: not %rustc_cfip --crate-type=rlib --cfg path_arg %s -o %t/lib.rlib 2>&1 | FileCheck %s --check-prefix=PATH
// LITERAL: error: expected identifier
// LITERAL-NEXT: harden_vars_fn_literal_arg.rs:[[@LINE+5]]:24
// PATH: error: expected `,`
// PATH-NEXT: harden_vars_fn_literal_arg.rs:[[@LINE+10]]:25

#[cfg(not(path_arg))]
#[cfip::harden_vars_fn("var")]
pub fn value(a: i32) -> i32 {
    let var: i32 = a;
    var + 1
}

#[cfg(path_arg)]
#[cfip::harden_vars_fn(a::var)]
pub fn value(a: i32) -> i32 {
    let var: i32 = a;
    var + 1
}
