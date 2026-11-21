; A drop function that does not take one pointer is reported as an error, not a broken module.
; RUN: not opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o /dev/null 2>&1 | FileCheck %s --implicit-check-not="LLVM ERROR"

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define void @internal_firv2_0_drop(ptr %value, i64 %length) {
  ret void
}

define i32 @victim() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @victim, ptr @internal_firv2_0_drop)
  ret i32 1
}

; CHECK: error: {{.*}}internal_firv2_0_identifier
