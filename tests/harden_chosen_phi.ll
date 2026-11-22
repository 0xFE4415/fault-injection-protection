; SSA repair after cloning a shared successor merges a critical value in a new PHI; its users stay critical.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: clang -w %t.ll -o %t.out
; RUN: %t.out | FileCheck %s --check-prefix=OUT
; OUT: 40

target triple = "x86_64-redhat-linux-gnu"

declare i32 @cfip_harden_var_(i32)
declare i32 @printf(ptr, ...)
@fmt = private constant [4 x i8] c"%d\0A\00"

define i32 @callee(i32 %x) {
  %y = mul i32 %x, 5
  ret i32 %y
}

; CHECK-LABEL: define i32 @main()
; CHECK: call i32 @callee.hardened.0(
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
  br label %exit
exit:
  %r = call i32 @callee(i32 %v)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %r)
  ret i32 0
}
