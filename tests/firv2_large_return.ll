; RUN: opt -passes='firv2-internal' -load-pass-plugin=../build/lib/LLVMFirv2.so %s -S -o %t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out
; RUN: FileCheck %s --input-file=%t.ll

target triple = "x86_64-redhat-linux-gnu"

%struct.Triple = type { i64, i64, i64 }

declare void @internal_firv2_0_identifier(ptr, ptr)

define dso_local %struct.Triple @make_triple() {
  call void @internal_firv2_0_identifier(ptr @internal_firv2_0_eq, ptr @make_triple)
  ret %struct.Triple { i64 1, i64 2, i64 3 }
}

define i1 @internal_firv2_0_eq(ptr %x, ptr %y) {
  %x_struct = load %struct.Triple, ptr %x, align 8
  %y_struct = load %struct.Triple, ptr %y, align 8
  %x_0 = extractvalue %struct.Triple %x_struct, 0
  %y_0 = extractvalue %struct.Triple %y_struct, 0
  %cmp_0 = icmp eq i64 %x_0, %y_0
  %x_1 = extractvalue %struct.Triple %x_struct, 1
  %y_1 = extractvalue %struct.Triple %y_struct, 1
  %cmp_1 = icmp eq i64 %x_1, %y_1
  %x_2 = extractvalue %struct.Triple %x_struct, 2
  %y_2 = extractvalue %struct.Triple %y_struct, 2
  %cmp_2 = icmp eq i64 %x_2, %y_2
  %cmp_01 = and i1 %cmp_0, %cmp_1
  %result = and i1 %cmp_01, %cmp_2
  ret i1 %result
}

define dso_local i32 @main() {
  %triple = call %struct.Triple @make_triple()
  %last = extractvalue %struct.Triple %triple, 2
  %last_i32 = trunc i64 %last to i32
  %exit_code = sub i32 %last_i32, 3
  ret i32 %exit_code
}

; CHECK-LABEL: define %struct.Triple @make_triple()
; CHECK-NOT: alloca ptr
; CHECK: [[SLOT1:%[0-9]+]] = alloca %struct.Triple
; CHECK-NEXT: [[SLOT2:%[0-9]+]] = alloca %struct.Triple
; CHECK-NOT: alloca ptr
; CHECK: [[CALL1:%[0-9]+]] = call %struct.Triple @make_triple.original()
; CHECK-NEXT: [[CALL2:%[0-9]+]] = call %struct.Triple @make_triple.original()
; CHECK-NEXT: store %struct.Triple [[CALL1]], ptr [[SLOT1]]
; CHECK-NEXT: store %struct.Triple [[CALL2]], ptr [[SLOT2]]
; CHECK-NEXT: call i1 @internal_firv2_0_eq(ptr [[SLOT1]], ptr [[SLOT2]])
