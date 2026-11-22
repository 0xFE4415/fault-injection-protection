; harden-all checks switch successors on a self loop and on a PHI with duplicate switch entries, and keeps an unreachable default valid.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

; The loop block is its own successor and also follows entry, so its check goes on a new edge block.
; CHECK-LABEL: define i32 @count_down(
; CHECK: switch i32 %{{.*}}, label %done [
; CHECK-NEXT: i32 0, label %done
; CHECK-NEXT: i32 1, label %loop.loop_crit_edge
; CHECK-NEXT: i32 2, label %loop.loop_crit_edge
; CHECK-NEXT: ]
; CHECK-LABEL: {{^}}loop.loop_crit_edge:
; CHECK: icmp eq i32 %{{.*}}, 1
; CHECK: icmp eq i32 %{{.*}}, 2
; CHECK: %switch_fault{{.*}} = xor i1
; CHECK: br label %loop
; CHECK-LABEL: {{^}}done:
; CHECK: icmp eq i32 %{{.*}}, 1
; CHECK: icmp eq i32 %{{.*}}, 2
; CHECK: %switch_fault{{.*}} = or i1
define i32 @count_down(i32 %start) {
entry:
  br label %loop
loop:
  %n = phi i32 [ %start, %entry ], [ %next, %loop ], [ %next, %loop ]
  %next = sub i32 %n, 1
  switch i32 %n, label %done [
    i32 0, label %done
    i32 1, label %loop
    i32 2, label %loop
  ]
done:
  ret i32 %n
}

; Both cases reach join from the switch block only, so the check goes in join itself.
; CHECK-LABEL: define i32 @pick(
; CHECK-NOT: crit_edge
; CHECK-LABEL: {{^}}join:
; CHECK: phi i32 [ 5, %entry ], [ 5, %entry ]
; CHECK: icmp eq i1 %{{.*}}, true
; CHECK: icmp eq i1 %{{.*}}, false
; CHECK: %switch_fault{{.*}} = xor i1
; CHECK-LABEL: {{^}}trap_block:
; CHECK: unreachable
define i32 @pick(i1 %c) {
entry:
  switch i1 %c, label %trap_block [
    i1 true, label %join
    i1 false, label %join
  ]
join:
  %r = phi i32 [ 5, %entry ], [ 5, %entry ]
  ret i32 %r
trap_block:
  unreachable
}

define i32 @main() {
  %a = call i32 @count_down(i32 7)
  %b = call i32 @count_down(i32 2)
  %c = call i32 @pick(i1 true)
  %d = call i32 @pick(i1 false)
  %ab = add i32 %a, %b
  %cd = add i32 %c, %d
  %sum = add i32 %ab, %cd
  %wrong = icmp ne i32 %sum, 17
  %result = zext i1 %wrong to i32
  ret i32 %result
}
