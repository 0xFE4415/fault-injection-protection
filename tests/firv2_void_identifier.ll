; A skipped void function must not keep its identifier call, or the link fails.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll
; RUN: FileCheck %s --input-file=%t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define void @nothing() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @nothing)
  ret void
}

define i32 @main() {
  call void @nothing()
  ret i32 0
}

; CHECK-NOT: call void @internal_firv2_0_identifier
