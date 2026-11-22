; Splitting a switch edge must keep a PHI that has the same value on every edge, so harden-all hardens it and does not read a deleted instruction.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

; CHECK-LABEL: define i32 @route(
; CHECK: switch i32 %selector, label %other [
; CHECK-NEXT: i32 1, label %dispatch.join_crit_edge
; CHECK-NEXT: i32 2, label %dispatch.join_crit_edge
; CHECK-NEXT: ]
; CHECK-LABEL: {{^}}join:
; CHECK: %[[FIRST:[0-9]+]] = phi i32 [ 5, %entry.join_crit_edge ], [ 5, %dispatch.join_crit_edge ]
; CHECK-NEXT: %[[SECOND:[0-9]+]] = phi i32 [ %barrier{{[^,]*}}, %entry.join_crit_edge ], [ %barrier{{[^,]*}}, %dispatch.join_crit_edge ]
; CHECK: %is_fault_detected = icmp ne i32 %[[FIRST]], %barrier
; CHECK: ret i32 %[[FIRST]]
define i32 @route(i32 %selector, i1 %skip) {
entry:
  br i1 %skip, label %join, label %dispatch
dispatch:
  switch i32 %selector, label %other [
    i32 1, label %join
    i32 2, label %join
  ]
join:
  %same = phi i32 [ 5, %entry ], [ 5, %dispatch ], [ 5, %dispatch ]
  ret i32 %same
other:
  ret i32 9
}

define i32 @main() {
  %skipped = call i32 @route(i32 0, i1 true)
  %first_case = call i32 @route(i32 1, i1 false)
  %second_case = call i32 @route(i32 2, i1 false)
  %default_case = call i32 @route(i32 3, i1 false)
  %both_cases = add i32 %first_case, %second_case
  %both_others = add i32 %skipped, %default_case
  %sum = add i32 %both_cases, %both_others
  %wrong = icmp ne i32 %sum, 24
  %result = zext i1 %wrong to i32
  ret i32 %result
}
