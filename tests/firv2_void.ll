; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll 2>&1 | FileCheck %s --check-prefix=LOG
; RUN: FileCheck %s --input-file=%t.ll

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define void @nothing() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @nothing)
  ret void
}

; LOG: Skipping void function nothing

; CHECK-NOT: nothing.original
; CHECK: define void @nothing()
