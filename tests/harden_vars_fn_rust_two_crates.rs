// REQUIRES: rustup
// Each crate restarts the macro counter, so the marker names must still differ between crates hardening different types.
// RUN: %build_cfip_macro
// RUN: rm -rf %t && mkdir -p %t
// RUN: %rustc_cfip --crate-type=rlib --crate-name cfip_lib --cfg cfip_lib %s -o %t/libcfip_lib.rlib
// RUN: %rustc_cfip --extern cfip_lib=%t/libcfip_lib.rlib %s -o %t/out
// RUN: %t/out | FileCheck %s
// CHECK: 13
// RUN: %rustc_cfip --crate-type=rlib --crate-name cfip_lib --cfg cfip_lib --emit=llvm-ir %s -o %t/lib.ll
// RUN: %rustc_cfip --extern cfip_lib=%t/libcfip_lib.rlib --emit=llvm-ir %s -o %t/bin.ll
// RUN: grep -o '@cfip_harden_var_[0-9a-f]*(' %t/lib.ll | sort -u > %t/lib.names
// RUN: grep -o '@cfip_harden_var_[0-9a-f]*(' %t/bin.ll | sort -u > %t/bin.names
// RUN: count 1 < %t/lib.names
// RUN: count 1 < %t/bin.names
// RUN: not grep -F -x -f %t/lib.names %t/bin.names

#[cfg(cfip_lib)]
#[cfip::harden_vars_fn(var)]
pub fn lib_value(a: u64) -> u64 {
    let var: (u64, u64) = (a, 3);
    var.0 + var.1
}

#[cfg(not(cfip_lib))]
#[cfip::harden_vars_fn(var)]
fn bin_value(a: i32) -> i32 {
    let var: i32 = a;
    var + 5
}

#[cfg(not(cfip_lib))]
fn main() {
    let count = std::env::args().count();
    println!("{}", cfip_lib::lib_value(count as u64 + 3) as i32 + bin_value(count as i32));
}
