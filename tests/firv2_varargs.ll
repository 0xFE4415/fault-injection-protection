; The wrapper cannot forward variadic arguments, so a variadic function is declined.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define i32 @variadic(i32 %count, ...) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @variadic)
  ret i32 %count
}

; CHECK-NOT: @variadic.original
; CHECK-NOT: call void @internal_firv2_0_identifier
