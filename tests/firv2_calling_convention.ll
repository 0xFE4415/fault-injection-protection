; Callers still call with fastcc, so the wrapper must keep the calling convention.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define internal fastcc i32 @identity(i32 %value) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @identity)
  ret i32 %value
}

define i32 @main() {
  %result = call fastcc i32 @identity(i32 0)
  ret i32 %result
}

; CHECK-LABEL: define i32 @main()
; CHECK: call fastcc i32 @identity(i32 0)
; CHECK: define internal fastcc i32 @identity(i32 %0)
