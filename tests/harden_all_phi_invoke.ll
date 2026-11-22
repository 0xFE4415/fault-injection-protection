; A PHI that merges an invoke result cannot reload that value before the invoke, so that entry is left as is.
; RUN: opt -passes='cfip<harden-all>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: clang++ -w %t.ll -o %t.out
; RUN: %t.out | FileCheck %s --check-prefix=OUT
; OUT: 8
; OUT-NEXT: 47

target triple = "x86_64-redhat-linux-gnu"

declare i32 @__gxx_personality_v0(...)
declare i32 @printf(ptr, ...)
@fmt = private constant [4 x i8] c"%d\0A\00"

define i32 @get(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}

; CHECK-LABEL: define i32 @f(
; CHECK-LABEL: {{^}}other:
; CHECK: store volatile i32 %b, ptr [[SLOT:%barrier_slot[0-9]*]],
; CHECK-NEXT: [[FROM_OTHER:%[^ ]+]] = load volatile i32, ptr [[SLOT]],
; CHECK-NEXT: br label %join
; CHECK-LABEL: {{^}}join:
; CHECK-NEXT: phi i8
; CHECK-NEXT: [[P1:%[0-9]+]] = phi i32 [ %v, %call ], [ %b, %other ]
; CHECK-NEXT: phi i32 [ %v, %call ], [ [[FROM_OTHER]], %other ]
define i32 @f(i1 %c, i32 %a, i32 %b) personality ptr @__gxx_personality_v0 {
entry:
  br i1 %c, label %call, label %other
call:
  %v = invoke i32 @get(i32 %a) to label %join unwind label %lpad
other:
  br label %join
join:
  %p = phi i32 [ %v, %call ], [ %b, %other ]
  %q = mul i32 %p, 2
  ret i32 %q
lpad:
  %lp = landingpad { ptr, i32 } cleanup
  resume { ptr, i32 } %lp
}

define i32 @main() {
  %x = call i32 @f(i1 true, i32 3, i32 0)
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %x)
  %y = call i32 @f(i1 false, i32 0, i32 47)
  %y.half = sdiv i32 %y, 2
  call i32 (ptr, ...) @printf(ptr @fmt, i32 %y.half)
  ret i32 0
}
