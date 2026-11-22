; Splitting a switch edge must keep a PHI of the critical value that has the same value on every edge, so the pass hardens it and does not read a deleted instruction.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

declare i32 @cfip_harden_var_(i32)

; CHECK-LABEL: define i32 @route(
; CHECK: switch i32 %input, label %other [
; CHECK-NEXT: i32 1, label %dispatch.join_crit_edge
; CHECK-NEXT: i32 2, label %dispatch.join_crit_edge
; CHECK-NEXT: ]
; CHECK-LABEL: {{^}}join:
; CHECK: %[[FIRST:[0-9]+]] = phi i32 [ %input, %entry ], [ %input, %dispatch.join_crit_edge ]
; CHECK-NEXT: %[[SECOND:[0-9]+]] = phi i32 [ %barrier{{[^,]*}}, %entry ], [ %barrier{{[^,]*}}, %dispatch.join_crit_edge ]
; CHECK: %is_fault_detected = icmp ne i32 %[[FIRST]], %barrier
; CHECK: ret i32 %[[FIRST]]
define i32 @route(i32 %input, i1 %skip) {
entry:
  %pin = call i32 @cfip_harden_var_(i32 %input)
  br i1 %skip, label %join, label %dispatch
dispatch:
  switch i32 %pin, label %other [
    i32 1, label %join
    i32 2, label %join
  ]
join:
  %same = phi i32 [ %pin, %entry ], [ %pin, %dispatch ], [ %pin, %dispatch ]
  ret i32 %same
other:
  ret i32 9
}

define i32 @main() {
  %skipped = call i32 @route(i32 7, i1 true)
  %first_case = call i32 @route(i32 1, i1 false)
  %second_case = call i32 @route(i32 2, i1 false)
  %default_case = call i32 @route(i32 3, i1 false)
  %both_cases = add i32 %first_case, %second_case
  %both_others = add i32 %skipped, %default_case
  %sum = add i32 %both_cases, %both_others
  %wrong = icmp ne i32 %sum, 19
  %result = zext i1 %wrong to i32
  ret i32 %result
}
