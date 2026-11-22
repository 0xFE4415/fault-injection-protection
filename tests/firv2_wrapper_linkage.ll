; The wrapper takes over the symbol, so it must keep its linkage, visibility and comdat.
; Two translation units that both define the linkonce_odr function must still link.
; RUN: rm -rf %t && split-file %s %t
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %t/first.ll -S -o %t/first.out.ll
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %t/second.ll -S -o %t/second.out.ll
; RUN: FileCheck %s --input-file=%t/first.out.ll
; RUN: clang %t/first.out.ll %t/second.out.ll -o %t/out
; RUN: %t/out

; CHECK: define linkonce_odr hidden i32 @shared() {{.*}}comdat

;--- first.ll
target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

$shared = comdat any

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) comdat($shared) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define linkonce_odr hidden i32 @shared() comdat {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @shared)
  ret i32 0
}

declare i32 @other()

define i32 @main() {
  %first = call i32 @shared()
  %second = call i32 @other()
  %sum = add i32 %first, %second
  ret i32 %sum
}

;--- second.ll
target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

$shared = comdat any

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) comdat($shared) {
  %x_value = load i32, ptr %x, align 4
  %y_value = load i32, ptr %y, align 4
  %result = icmp eq i32 %x_value, %y_value
  ret i1 %result
}

define linkonce_odr hidden i32 @shared() comdat {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @shared)
  ret i32 0
}

define i32 @other() {
  %value = call i32 @shared()
  ret i32 %value
}
