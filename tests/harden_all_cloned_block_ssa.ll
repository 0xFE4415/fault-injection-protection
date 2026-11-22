; Cloning a shared successor must repair SSA for values used outside it and for PHIs in its successors.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: define i32 @value_used_later(
; CHECK-LABEL: define i32 @value_used_by_phi(
define i32 @value_used_later(i1 %c, ptr %p) {
entry:
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
t0:
  %r = load i32, ptr %p
  br label %exit
exit:
  ret i32 %r
}

define i32 @value_used_by_phi(i1 %c, ptr %p) {
entry:
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
t0:
  %r = load i32, ptr %p
  br label %exit
exit:
  %s = phi i32 [ %r, %t0 ]
  ret i32 %s
}
