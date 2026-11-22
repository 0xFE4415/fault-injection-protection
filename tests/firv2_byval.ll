; The wrapper and its calls to the original must keep byval, or the argument is read from the wrong place.
; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll
; RUN: FileCheck %s --input-file=%t.ll
; RUN: llc -O2 -relocation-model=pic %t.ll -o %t.s
; RUN: clang %t.s -o %t.out
; RUN: %t.out

target triple = "x86_64-redhat-linux-gnu"

declare void @internal_firv2_0_identifier(ptr, ptr)

%struct.Triple = type { i64, i64, i64 }

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_value = load i64, ptr %x, align 8
  %y_value = load i64, ptr %y, align 8
  %result = icmp eq i64 %x_value, %y_value
  ret i1 %result
}

define i64 @last(ptr byval(%struct.Triple) align 8 %triple) {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @last)
  %last_ptr = getelementptr inbounds %struct.Triple, ptr %triple, i32 0, i32 2
  %last = load i64, ptr %last_ptr, align 8
  ret i64 %last
}

define i32 @main() {
  %triple = alloca %struct.Triple, align 8
  %last_ptr = getelementptr inbounds %struct.Triple, ptr %triple, i32 0, i32 2
  store i64 42, ptr %last_ptr, align 8
  %last = call i64 @last(ptr byval(%struct.Triple) align 8 %triple)
  %last_i32 = trunc i64 %last to i32
  %exit_code = sub i32 %last_i32, 42
  ret i32 %exit_code
}

; CHECK-LABEL: define i64 @last(ptr byval(%struct.Triple) align 8 %0)
; CHECK: call i64 @last.original(ptr byval(%struct.Triple) align 8 %0)
; CHECK-NEXT: call i64 @last.original(ptr byval(%struct.Triple) align 8 %0)
