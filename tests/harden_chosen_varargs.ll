; A critical value passed as a variadic argument has no matching parameter in the callee.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll 2> %t.err
; RUN: FileCheck %s < %t.ll
; RUN: FileCheck %s --check-prefix=WARN < %t.err

declare i32 @cfip_harden_var_(i32)

define i32 @variadic(i32 %n, ...) {
  %r = add i32 %n, 1
  ret i32 %r
}

; CHECK-LABEL: define i32 @main()
; CHECK-NOT: cfip_harden_var_
; CHECK: call i32 (i32, ...) @variadic(i32 0, i32 42)
define i32 @main() {
  %val = call i32 @cfip_harden_var_(i32 42)
  %r = call i32 (i32, ...) @variadic(i32 0, i32 %val)
  ret i32 %r
}

; The fixed argument is still hardened in the callee.
; CHECK-LABEL: define i32 @fixed_and_variadic()
; CHECK: call i32 (i32, ...) @variadic.hardened.0(i32 42, i32 42)
define i32 @fixed_and_variadic() {
  %val = call i32 @cfip_harden_var_(i32 42)
  %r = call i32 (i32, ...) @variadic(i32 %val, i32 %val)
  ret i32 %r
}

; CHECK-LABEL: define private i32 @variadic.hardened.0(i32 %n, ...)
; CHECK: add i32 %n, 1
; CHECK: add i32 %{{[^ ,]*barrier[^ ,]*}}, 1

; WARN: WARNING: critical value passed as a variadic argument to variadic is not hardened in the callee
