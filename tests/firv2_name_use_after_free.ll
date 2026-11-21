; Freed heap memory is poisoned so that reading the old function name after setName is visible.
; RUN: env GLIBC_TUNABLES=glibc.malloc.tcache_count=0:glibc.malloc.perturb=170 opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o - | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define i32 @hardened_function_name_with_thirty_two() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @hardened_function_name_with_thirty_two)
  ret i32 1
}

define i32 @main() {
  %value = call i32 @hardened_function_name_with_thirty_two()
  ret i32 %value
}

; CHECK-LABEL: define i32 @main()
; CHECK: call i32 @hardened_function_name_with_thirty_two()
; CHECK: define i32 @hardened_function_name_with_thirty_two()
