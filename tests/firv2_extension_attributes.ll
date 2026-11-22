; zeroext and signext are part of the ABI and must survive on the wrapper and on its calls.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i8, ptr %x, align 1
  %y_value = load i8, ptr %y, align 1
  %result = icmp eq i8 %x_value, %y_value
  ret i1 %result
}

define zeroext i8 @narrow(i8 signext %value) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @narrow)
  ret i8 %value
}

; CHECK-LABEL: define zeroext i8 @narrow(i8 signext %0)
; CHECK: call zeroext i8 @narrow.original(i8 signext %0)
; CHECK-NEXT: call zeroext i8 @narrow.original(i8 signext %0)
