; A shared successor is not duplicated, so its values keep their single definition for later uses and PHIs.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s --implicit-check-not=.clone < %t.ll

; CHECK-LABEL: define i32 @value_used_later(
; CHECK: br i1 %c, label %t1, label %entry.t0_crit_edge
; CHECK-LABEL: {{^}}t0:{{.*}}; preds = %entry.t0_crit_edge, %t1{{$}}
; CHECK: %r = load i32, ptr %p
; CHECK-NOT: load i32, ptr %p
; CHECK: ret i32 %r
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

; CHECK-LABEL: define i32 @value_used_by_phi(
; CHECK: br i1 %c, label %t1, label %entry.t0_crit_edge
; CHECK-LABEL: {{^}}t0:{{.*}}; preds = %entry.t0_crit_edge, %t1{{$}}
; CHECK: %r = load i32, ptr %p
; CHECK-NOT: load i32, ptr %p
; CHECK-LABEL: {{^}}exit:{{.*}}; preds = %t0{{$}}
; CHECK-NEXT: phi i32 [ %r, %t0 ]{{$}}
; CHECK-NEXT: phi i32 [ %{{[^ ,]*barrier[^ ,]*}}, %t0 ]{{$}}
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
