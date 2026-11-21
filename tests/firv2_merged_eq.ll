; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out
; RUN: cat %t.ll | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr)
declare void @internal_firv2_1_identifier(ptr)

; function merging leaves no function or alias named internal_firv2_1_eq
@merged_eq = internal alias i1 (ptr, ptr), ptr @internal_firv2_0_eq

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %left = load i32, ptr %x, align 4
  %right = load i32, ptr %y, align 4
  %equal = icmp eq i32 %left, %right
  ret i1 %equal
}

define i32 @first() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq)
  ret i32 1
}

define i32 @second() {
  call void @internal_firv2_1_identifier(ptr @merged_eq)
  ret i32 2
}

define i32 @main() {
  %first_value = call i32 @first()
  %second_value = call i32 @second()
  %sum = add i32 %first_value, %second_value
  %result = sub i32 %sum, 3
  ret i32 %result
}

; CHECK-NOT: call void @internal_firv2_

; CHECK-LABEL: define {{.*}}i32 @first()
; CHECK: call i32 @first.original()
; CHECK: call i32 @first.original()
; CHECK: call i1 @internal_firv2_0_eq(

; CHECK-LABEL: define {{.*}}i32 @second()
; CHECK: call i32 @second.original()
; CHECK: call i32 @second.original()
; CHECK: call i1 @internal_firv2_0_eq(
