; RUN: not opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o /dev/null 2>&1 | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier()

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define i32 @victim() {
  call void @internal_firv2_0_identifier()
  ret i32 1
}

; CHECK: error: cmp function not found for: internal_firv2_0_identifier
