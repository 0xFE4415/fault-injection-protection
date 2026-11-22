; A hardened callee writes a critical value through a pointer argument; the caller's reads of it are critical too.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

declare i32 @cfip_harden_var_(i32)

define void @compute(i32 %v, ptr %out) {
  %x = add i32 %v, 1
  store i32 %x, ptr %out
  ret void
}

define void @compute_sret(ptr sret(i32) %out, i32 %v) {
  %x = add i32 %v, 1
  store i32 %x, ptr %out
  ret void
}

; CHECK-LABEL: define i32 @out_pointer()
; CHECK: call void @compute.hardened.0.1(
; CHECK: sub i32 %r, 43
; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 43
define i32 @out_pointer() {
  %out = alloca i32
  %val = call i32 @cfip_harden_var_(i32 42)
  call void @compute(i32 %val, ptr %out)
  %r = load i32, ptr %out
  %y = sub i32 %r, 43
  ret i32 %y
}

; CHECK-LABEL: define i32 @sret_return()
; CHECK: call void @compute_sret.hardened.0.1(
; CHECK: sub i32 %r, 43
; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 43
define i32 @sret_return() {
  %out = alloca i32
  %val = call i32 @cfip_harden_var_(i32 42)
  call void @compute_sret(ptr sret(i32) %out, i32 %val)
  %r = load i32, ptr %out
  %y = sub i32 %r, 43
  ret i32 %y
}
