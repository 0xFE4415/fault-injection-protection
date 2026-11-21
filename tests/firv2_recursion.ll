; Recursive calls inside the original must not re-enter the wrapper, or the cost doubles at each level.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define i32 @depth(i32 %remaining) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @depth)
  %done = icmp eq i32 %remaining, 0
  br i1 %done, label %bottom, label %recurse

recurse:
  %next = sub i32 %remaining, 1
  %below = call i32 @depth(i32 %next)
  %result = add i32 %below, 1
  ret i32 %result

bottom:
  ret i32 0
}

; CHECK-LABEL: define internal i32 @depth.original(
; CHECK: call i32 @depth.original(
; CHECK-LABEL: define i32 @depth(
