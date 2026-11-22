; An inalloca or preallocated argument can be passed to only one call, so hardening it is reported as an error.
; RUN: not opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o /dev/null 2>&1 | FileCheck %s --implicit-check-not="LLVM ERROR"

target triple = "i686-pc-windows-msvc"

declare void @internal_firv2_0_identifier(ptr, ptr)
declare void @internal_firv2_1_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define i1 @internal_firv2_1_eq(ptr %x, ptr %y) {
  ret i1 true
}

define i32 @in_alloca(ptr inalloca(i32) %value) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @in_alloca)
  %loaded = load i32, ptr %value, align 4
  ret i32 %loaded
}

define i32 @pre_allocated(ptr preallocated(i32) %value) {
  call void @internal_firv2_1_identifier(ptr @internal_firv2_1_eq, ptr @pre_allocated)
  %loaded = load i32, ptr %value, align 4
  ret i32 %loaded
}

; CHECK-DAG: error: {{.*}}in_alloca{{.*}}internal_firv2_0_identifier
; CHECK-DAG: error: {{.*}}pre_allocated{{.*}}internal_firv2_1_identifier
