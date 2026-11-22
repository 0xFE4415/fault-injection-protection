; Branch hardening puts the check of a shared successor on its edge, so every path runs the one hardened successor.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s --implicit-check-not=.clone < %t.ll

; CHECK-LABEL: define i32 @f(
define i32 @f(i1 %c, i32 %a) {
entry:
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
; CHECK-LABEL: {{^}}t0:{{.*}}; preds = %entry.t0_crit_edge, %t1{{$}}
; CHECK: mul i32 %a, 3
; CHECK: mul i32 %{{[^ ,]*barrier[^ ,]*}}, 3
; CHECK-NOT: mul
t0:
  %r = mul i32 %a, 3
  ret i32 %r
}
