; A critical value merged by a PHI in a shared successor stays critical, and every path runs the hardened code.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: clang -w %t.ll -o %t.out
; RUN: %t.out | FileCheck %s --check-prefix=OUT
; OUT: 40
; OUT-NEXT: 40

target triple = "x86_64-redhat-linux-gnu"

declare i32 @cfip_harden_var_(i32)
declare i32 @printf(ptr, ...)
@fmt = private constant [4 x i8] c"%d\0A\00"

define i32 @callee(i32 %x) {
  %y = mul i32 %x, 5
  ret i32 %y
}

; CHECK-LABEL: define i32 @main()
; CHECK-NOT: .clone
; CHECK-NOT: call i32 @callee(
; CHECK-LABEL: {{^}}t0:
; CHECK: [[P1:%[0-9]+]] = phi i32 [ 3, %entry.t0_crit_edge ], [ 7, %t1 ]
; CHECK-NEXT: [[P2:%[0-9]+]] = phi i32 [ 3, %entry.t0_crit_edge ], [ 7, %t1 ]
; CHECK-NEXT: icmp ne i32 [[P1]], [[P2]]
; CHECK: [[V1:%[0-9]+]] = add i32 [[P1]], 1
; CHECK-NEXT: [[V2:%[0-9]+]] = add i32 [[P1]], 1
; CHECK-NEXT: icmp ne i32 [[V1]], [[V2]]
; CHECK: call i32 @callee.hardened.0(
; CHECK: call i32 @callee.hardened.0(
; CHECK-NOT: call i32 @callee(
; CHECK-LABEL: define private i32 @callee.hardened.0(
define i32 @main() {
entry:
  %val = call i32 @cfip_harden_var_(i32 3)
  %c = icmp eq i32 %val, 3
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
t0:
  %p = phi i32 [ %val, %entry ], [ 7, %t1 ]
  %v = add i32 %p, 1
  %r0 = call i32 @callee(i32 %v)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %r0)
  br label %exit
exit:
  %r = call i32 @callee(i32 %v)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %r)
  ret i32 0
}
