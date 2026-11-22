; An eq function that does not take two pointers is reported as an error, not a broken module.
; RUN: not opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o /dev/null 2>&1 | FileCheck %s --implicit-check-not="LLVM ERROR"

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, i64 %x_length, ptr %y, i64 %y_length) {
  ret i1 true
}

define { ptr, i64 } @victim() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @victim)
  ret { ptr, i64 } zeroinitializer
}

; CHECK: error: {{.*}}internal_firv2_0_identifier
