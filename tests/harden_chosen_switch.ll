; A switch on a critical value must get the same successor check as a conditional branch.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll
; A fault that takes the wrong switch edge must trap.
; RUN: sed 's/i32 1234, label %grant/i32 1234, label %deny/' %t.ll > %t.case_to_default.ll
; RUN: not --crash lli %t.case_to_default.ll
; RUN: sed 's/switch i32 %input, label %deny/switch i32 %input, label %grant/' %t.ll > %t.default_to_case.ll
; RUN: not --crash lli %t.default_to_case.ll

declare i32 @cfip_harden_var_(i32)

; SROA promotes the stored switch condition, so each check compares %input again.
; CHECK-LABEL: define i32 @select(
; CHECK: switch i32 %input, label %deny [
; CHECK-NEXT: i32 1234, label %grant
; CHECK-NEXT: i32 5678, label %grant
; CHECK-NEXT: i32 42, label %deny
; CHECK-NEXT: i32 7, label %dispatch.shared_crit_edge
; CHECK-NEXT: ]

; CHECK-LABEL: {{^}}dispatch.shared_crit_edge:
; CHECK-NEXT: %[[IS_7:.*]] = icmp eq i32 %input, 7
; CHECK-NEXT: %switch_fault{{.*}} = xor i1 %[[IS_7]], true
; CHECK: br label %shared

; CHECK-LABEL: {{^}}grant:
; CHECK-NEXT: %[[IS_1234:.*]] = icmp eq i32 %input, 1234
; CHECK-NEXT: %[[IS_5678:.*]] = icmp eq i32 %input, 5678
; CHECK-NEXT: %[[IS_EITHER:.*]] = or i1 %[[IS_1234]], %[[IS_5678]]
; CHECK-NEXT: %switch_fault{{.*}} = xor i1 %[[IS_EITHER]], true
; CHECK: label %error_handling

; The default successor is also the target of case 42, so 42 is not a fault there.
; CHECK-LABEL: {{^}}deny:
; CHECK-NEXT: %[[IS_1234:.*]] = icmp eq i32 %input, 1234
; CHECK-NEXT: %[[IS_5678:.*]] = icmp eq i32 %input, 5678
; CHECK-NEXT: %[[EITHER:.*]] = or i1 %[[IS_1234]], %[[IS_5678]]
; CHECK-NEXT: %[[IS_7:.*]] = icmp eq i32 %input, 7
; CHECK-NEXT: %switch_fault{{.*}} = or i1 %[[EITHER]], %[[IS_7]]
; CHECK-NOT: 42
; CHECK: label %error_handling

; CHECK-LABEL: {{^}}shared:
; CHECK: phi i32 [ 2, %dispatch.shared_crit_edge ], [ 3, %bypass ]
define i32 @select(i32 %input, i1 %other) {
entry:
  %pin = call i32 @cfip_harden_var_(i32 %input)
  br i1 %other, label %bypass, label %dispatch
bypass:
  br label %shared
dispatch:
  switch i32 %pin, label %deny [
    i32 1234, label %grant
    i32 5678, label %grant
    i32 42, label %deny
    i32 7, label %shared
  ]
grant:
  ret i32 1
deny:
  ret i32 0
shared:
  %result = phi i32 [ 2, %dispatch ], [ 3, %bypass ]
  ret i32 %result
}

define i32 @check(i32 %input, i1 %other, i32 %expected) {
  %result = call i32 @select(i32 %input, i1 %other)
  %wrong = icmp ne i32 %result, %expected
  %wrong_count = zext i1 %wrong to i32
  ret i32 %wrong_count
}

define i32 @main() {
  %w1 = call i32 @check(i32 1234, i1 false, i32 1)
  %w2 = call i32 @check(i32 5678, i1 false, i32 1)
  %w3 = call i32 @check(i32 42, i1 false, i32 0)
  %w4 = call i32 @check(i32 7, i1 false, i32 2)
  %w5 = call i32 @check(i32 0, i1 false, i32 0)
  %w6 = call i32 @check(i32 0, i1 true, i32 3)
  %s2 = add i32 %w1, %w2
  %s3 = add i32 %s2, %w3
  %s4 = add i32 %s3, %w4
  %s5 = add i32 %s4, %w5
  %s6 = add i32 %s5, %w6
  ret i32 %s6
}
