; A critical branch that targets its own block on the false edge exits the loop without a fault.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.0.ll
; RUN: clang -w %t.0.ll -o %t.0
; RUN: %t.0 | FileCheck %s --check-prefix=OUT
; RUN: opt -passes='cfip<atomic-state>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.1.ll
; RUN: clang -w %t.1.ll -o %t.1
; RUN: %t.1 | FileCheck %s --check-prefix=OUT
; RUN: opt -passes='cfip<check-asap>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.2.ll
; RUN: clang -w %t.2.ll -o %t.2
; RUN: %t.2 | FileCheck %s --check-prefix=OUT
; OUT: 12

target triple = "x86_64-redhat-linux-gnu"

declare i32 @cfip_harden_var_(i32)
declare i32 @printf(ptr, ...)
@fmt = private constant [4 x i8] c"%d\0A\00"

define i32 @main() {
entry:
  %a = call i32 @cfip_harden_var_(i32 84)
  br label %loop
loop:
  %x = phi i32 [ %a, %entry ], [ %y, %loop ]
  %y = phi i32 [ 36, %entry ], [ %rem, %loop ]
  %rem = srem i32 %x, %y
  %done = icmp eq i32 %rem, 0
  br i1 %done, label %exit, label %loop
exit:
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %y)
  ret i32 0
}
