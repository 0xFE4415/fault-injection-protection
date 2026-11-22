; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out
; RUN: cat %t.ll | FileCheck %s --implicit-check-not=.clone

; CHECK-LABEL: main
define i32 @main(i1 %0) #0 {
; CHECK: %unexpected_result = sub i1 false, %0
; CHECK: br i1 %0, label %true1, label %.true0_crit_edge
  br i1 %0, label %true1, label %true0

; CHECK-LABEL: .true0_crit_edge:
  ; CHECK-NEXT: %false_branch_fault = icmp ne i1 %unexpected_result, false
  ; CHECK-NEXT: zext i1
  ; CHECK-NEXT: or i8 0
  ; CHECK-NEXT: br label %true0

; CHECK-LABEL: true0:
true0:
  ; CHECK-NOT: branch_fault
  ; CHECK: trunc
  ; CHECK: br i1

; CHECK-LABEL: ret_block:
  ; CHECK: ret i32 0

  ret i32 0
; CHECK-LABEL: true1:
true1:
  ; CHECK: %true_branch_fault = icmp ne i1 %unexpected_result, true
  ; CHECK: zext
  ; CHECK: or
  ; CHECK: br label %true0
  br label %true0

; CHECK-LABEL: error_handling:
}

attributes #0 = { optnone noinline }
