; Hardening the first PHI inserts its check before the second PHI.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: define i32 @f(
define i32 @f(i1 %c, i32 %a, i32 %b) {
entry:
  br i1 %c, label %l, label %r
l:
  br label %m
r:
  br label %m
; CHECK-LABEL: m:
m:
  ; CHECK-COUNT-4: phi i32
  ; CHECK-NOT: phi
  %x = phi i32 [ %a, %l ], [ %b, %r ]
  %y = phi i32 [ %b, %l ], [ %a, %r ]
  %s = add i32 %x, %y
  ret i32 %s
}
