; RUN: not opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o /dev/null 2>&1 | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  ret i1 true
}

define i32 @hardened() {
  ret i32 1
}

define i32 @caller() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @hardened)
  %value = call i32 @hardened()
  ret i32 %value
}

; CHECK: error: internal_firv2_0_identifier is called from caller, but hardens hardened
