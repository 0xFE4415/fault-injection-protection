; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out
; RUN: FileCheck %s --input-file=%t.ll

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define dso_local i32 @subtract(i32 %minuend, i32 %subtrahend) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @subtract)
  %difference = sub i32 %minuend, %subtrahend
  ret i32 %difference
}

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define dso_local i32 @main() {
  %difference = call i32 @subtract(i32 7, i32 7)
  ret i32 %difference
}

; CHECK-LABEL: define i32 @subtract(i32 %0, i32 %1)
; CHECK: call i32 @subtract.original(i32 %0, i32 %1)
; CHECK-NEXT: call i32 @subtract.original(i32 %0, i32 %1)
