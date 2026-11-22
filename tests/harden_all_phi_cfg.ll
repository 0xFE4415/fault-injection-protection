; Cloning shared successors keeps SSA valid and the results unchanged for PHIs, loops and repeated edges.
; RUN: clang -w %s -o %t.ref
; RUN: timeout 10 %t.ref > %t.ref.txt
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.0.ll
; RUN: FileCheck %s < %t.0.ll
; RUN: clang -w %t.0.ll -o %t.0
; RUN: timeout 10 %t.0 | diff %t.ref.txt -
; RUN: opt -passes='cfip<harden-all;check-asap>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.1.ll
; RUN: clang -w %t.1.ll -o %t.1
; RUN: timeout 10 %t.1 | diff %t.ref.txt -
; RUN: opt -passes='cfip<harden-all;atomic-state>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.2.ll
; RUN: clang -w %t.2.ll -o %t.2
; RUN: timeout 10 %t.2 | diff %t.ref.txt -
; RUN: clang -w -O2 %t.0.ll -o %t.3
; RUN: timeout 10 %t.3 | diff %t.ref.txt -

target triple = "x86_64-redhat-linux-gnu"
declare i32 @printf(ptr, ...)
@fmt = private constant [4 x i8] c"%d\0A\00"

; The branch in loop targets loop itself, so the predecessor and the successor are the same block.
; CHECK-LABEL: define i32 @self_loop(
; CHECK: label %loop.clone, label %exit.clone
; CHECK-LABEL: {{^}}loop.clone:
; CHECK: label %loop, label %exit
define i32 @self_loop(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 1, %entry ], [ %acc.next, %loop ]
  %acc.next = mul i32 %acc, 3
  %i.next = add i32 %i, 1
  %c = icmp slt i32 %i.next, %n
  br i1 %c, label %loop, label %exit
exit:
  %r = phi i32 [ %acc.next, %loop ]
  %r2 = add i32 %r, %i.next
  ret i32 %r2
}

; Both edges of the branch in pre target m.
; CHECK-LABEL: define i32 @same_target(
; CHECK: label %m.clone, label %m.clone1
define i32 @same_target(i1 %c, i1 %d, i32 %a) {
entry:
  br i1 %d, label %other, label %pre
pre:
  %x = add i32 %a, 7
  br i1 %c, label %m, label %m
other:
  br label %m
m:
  %p = phi i32 [ %x, %pre ], [ %x, %pre ], [ 100, %other ]
  %q = mul i32 %p, 2
  ret i32 %q
}

; CHECK-LABEL: define i32 @phi_in_shared(
; CHECK: {{^}}join:{{.*}}; preds = %small.clone, %big.clone, %small, %big
define i32 @phi_in_shared(i1 %c, i32 %a, i32 %b) {
entry:
  %s0 = add i32 %a, 1
  br i1 %c, label %t1, label %t0
t1:
  %s1 = add i32 %b, 2
  br label %t0
t0:
  %p = phi i32 [ %s0, %entry ], [ %s1, %t1 ]
  %v = mul i32 %p, %p
  %w = icmp ugt i32 %v, 50
  br i1 %w, label %big, label %small
big:
  br label %join
small:
  br label %join
join:
  %res = phi i32 [ %v, %big ], [ %p, %small ]
  %res2 = add i32 %res, %v
  ret i32 %res2
}

; CHECK-LABEL: define i32 @nested_loops(
; CHECK-LABEL: {{^}}inner.clone:
; CHECK-LABEL: {{^}}outer.latch.clone:
define i32 @nested_loops(i32 %n) {
entry:
  br label %outer
outer:
  %i = phi i32 [ 0, %entry ], [ %i.next, %outer.latch ]
  %sum = phi i32 [ 0, %entry ], [ %sum.inner, %outer.latch ]
  br label %inner
inner:
  %j = phi i32 [ 0, %outer ], [ %j.next, %inner ]
  %sum.inner = phi i32 [ %sum, %outer ], [ %sum.next, %inner ]
  %t = mul i32 %i, %j
  %sum.next = add i32 %sum.inner, %t
  %j.next = add i32 %j, 1
  %jc = icmp slt i32 %j.next, %i
  br i1 %jc, label %inner, label %outer.latch
outer.latch:
  %i.next = add i32 %i, 1
  %ic = icmp slt i32 %i.next, %n
  br i1 %ic, label %outer, label %exit
exit:
  ret i32 %sum.inner
}

; The branch in latch targets the loop header, so the PHI in the cloned header uses a value
; that reaches latch from both the header and its clone.
; CHECK-LABEL: define i64 @count_zero_flags(
; CHECK-LABEL: {{^}}latch:
; CHECK: [[I:%[0-9]+]] = phi i64 {{.*}}%header.clone{{.*}}%header
; CHECK-LABEL: {{^}}header.clone:
; CHECK-NEXT: phi i64 [ [[I]], %latch ]
define i64 @count_zero_flags(ptr %flags) {
entry:
  br label %header
header:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %i.next = add i64 %i, 1
  %p = getelementptr i8, ptr %flags, i64 %i
  %f = load i8, ptr %p
  %z = icmp eq i8 %f, 0
  br i1 %z, label %latch, label %found
latch:
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %exit, label %header
found:
  ret i64 %i
exit:
  ret i64 99
}

@zeros = private constant [3 x i8] zeroinitializer
@third = private constant [3 x i8] c"\00\00\01"

define i32 @main() {
  %f1 = call i64 @count_zero_flags(ptr @zeros)
  %f1.32 = trunc i64 %f1 to i32
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %f1.32)
  %f2 = call i64 @count_zero_flags(ptr @third)
  %f2.32 = trunc i64 %f2 to i32
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %f2.32)
  %a = call i32 @self_loop(i32 1)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %a)
  %b = call i32 @self_loop(i32 5)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %b)
  %c1 = call i32 @same_target(i1 true, i1 false, i32 3)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %c1)
  %c2 = call i32 @same_target(i1 false, i1 true, i32 3)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %c2)
  %d1 = call i32 @phi_in_shared(i1 true, i32 3, i32 4)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %d1)
  %d2 = call i32 @phi_in_shared(i1 false, i32 3, i32 40)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %d2)
  %d3 = call i32 @phi_in_shared(i1 true, i32 30, i32 40)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %d3)
  %e = call i32 @nested_loops(i32 6)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %e)
  ret i32 0
}
