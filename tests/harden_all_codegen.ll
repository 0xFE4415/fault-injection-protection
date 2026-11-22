; Code generation must not merge the two copies of a hardened instruction.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: llc -O0 %t.ll -o %t.O0.s
; RUN: FileCheck %s < %t.O0.s
; RUN: sed -nE 's/.*(cmp[bwlq][[:space:]]+(%[a-z0-9]+), \2)$/SAME-REGISTER \1/p' %t.O0.s | FileCheck --allow-empty --check-prefix=SAME %s
; RUN: llc -O3 %t.ll -o %t.O3.s
; RUN: FileCheck %s < %t.O3.s
; RUN: sed -nE 's/.*(cmp[bwlq][[:space:]]+(%[a-z0-9]+), \2)$/SAME-REGISTER \1/p' %t.O3.s | FileCheck --allow-empty --check-prefix=SAME %s
; RUN: sed -nE -f %S/Inputs/phi_copies.sed %t.O3.s | FileCheck --check-prefix=PHI %s
; SAME-NOT: SAME-REGISTER

target triple = "x86_64-redhat-linux-gnu"

; CHECK-LABEL: check_pin:
; CHECK-COUNT-2: $1234
; CHECK-LABEL: .Lfunc_end0:
define i32 @check_pin(i32 %pin) {
  %ok = icmp eq i32 %pin, 1234
  br i1 %ok, label %grant, label %deny
grant:
  ret i32 1
deny:
  ret i32 0
}

; CHECK-LABEL: vector_add:
; CHECK-COUNT-2: paddd
; CHECK-LABEL: .Lfunc_end1:
define <4 x i32> @vector_add(<4 x i32> %a, <4 x i32> %b) {
  %r = add <4 x i32> %a, %b
  ret <4 x i32> %r
}

; CHECK-LABEL: wide_add:
; CHECK-COUNT-2: adcq
; CHECK-LABEL: .Lfunc_end2:
define i128 @wide_add(i128 %a, i128 %b) {
  %r = add i128 %a, %b
  ret i128 %r
}

; The register stored to the slot is the second copy of the first PHI, so it must not be the register it is compared with.
; CHECK-LABEL: two_phis:
; CHECK-LABEL: .Lfunc_end3:
; PHI: PHI-COPIES-SEPARATE
; PHI-NOT: PHI-COPIES-MERGED
define i32 @two_phis(i1 %c, i32 %a, i32 %b) {
entry:
  br i1 %c, label %l, label %r
l:
  br label %m
r:
  br label %m
m:
  %x = phi i32 [ %a, %l ], [ %b, %r ]
  %y = phi i32 [ %b, %l ], [ %a, %r ]
  %s = add i32 %x, %y
  ret i32 %s
}
