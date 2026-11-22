; The temporary for the second sret call must meet the alignment the sret parameter promises, or aligned stores in the original fault.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-redhat-linux-gnu"

%struct.Pair = type { i64, i64 }

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define void @make_pair(ptr sret(%struct.Pair) align 64 %result) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @make_pair)
  store <2 x i64> zeroinitializer, ptr %result, align 64
  ret void
}

; CHECK-LABEL: define void @make_pair(ptr sret(%struct.Pair) align 64 %0)
; CHECK: %[[TEMPORARY:[0-9]+]] = alloca %struct.Pair, align 64
; CHECK: call void @make_pair.original(ptr sret(%struct.Pair) align 64 %[[TEMPORARY]])
