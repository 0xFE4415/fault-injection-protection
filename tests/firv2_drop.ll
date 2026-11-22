; The second result is only compared, so the drop function from the identifier call runs on its slot after the comparison.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

%struct.Pair = type { i64, i64 }

declare void @internal_firv2_0_identifier(ptr, ptr, ptr)
declare void @internal_firv2_1_identifier(ptr, ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define void @internal_firv2_0_drop(ptr %value) {
  ret void
}

define ptr @make() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @make, ptr @internal_firv2_0_drop)
  ret ptr null
}

define i1 @internal_firv2_1_eq(ptr %x, ptr %y) {
  ret i1 true
}

define void @internal_firv2_1_drop(ptr %value) {
  ret void
}

define void @make_pair(ptr sret(%struct.Pair) %result) {
  call void @internal_firv2_1_identifier(ptr @internal_firv2_1_eq, ptr @make_pair, ptr @internal_firv2_1_drop)
  store %struct.Pair zeroinitializer, ptr %result, align 8
  ret void
}

; CHECK: define internal void @internal_firv2_0_drop(ptr %value)
; CHECK: define internal void @internal_firv2_1_drop(ptr %value)

; CHECK-LABEL: define ptr @make()
; CHECK: %[[FIRST:[0-9]+]] = alloca ptr
; CHECK-NEXT: %[[SECOND:[0-9]+]] = alloca ptr
; CHECK: call i1 @internal_firv2_0_eq(ptr %[[FIRST]], ptr %[[SECOND]])
; CHECK-NEXT: call void @internal_firv2_0_drop(ptr %[[SECOND]])

; CHECK-LABEL: define void @make_pair(ptr sret(%struct.Pair) %0)
; CHECK: %[[TEMPORARY:[0-9]+]] = alloca %struct.Pair
; CHECK: call i1 @internal_firv2_1_eq(ptr %0, ptr %[[TEMPORARY]])
; CHECK-NEXT: call void @internal_firv2_1_drop(ptr %[[TEMPORARY]])
