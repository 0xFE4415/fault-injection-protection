#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Transforms/IPO/AlwaysInliner.h"
#include <limits>
#include <string>
#include <utility>

using namespace llvm;

namespace {

struct Firv2 : PassInfoMixin<Firv2> {
  void build_function(Function *function, Function *original_function,
                      Function *cmp_function, Function *drop_function) {
    LLVMContext &Ctx = function->getContext();
    auto *i1_ty = Type::getInt1Ty(Ctx);
    AttributeList signature_attributes =
        original_function->getAttributes().removeFnAttributes(Ctx);
    function->setAttributes(signature_attributes);
    function->addFnAttr(Attribute::AlwaysInline);
    original_function->setLinkage(GlobalValue::LinkageTypes::InternalLinkage);
    original_function->setComdat(nullptr);
    BasicBlock *block = BasicBlock::Create(Ctx, "entry", function);
    IRBuilder<> builder(block);
    auto *comparison_result =
        builder.CreateAlloca(i1_ty, nullptr, "comparison_result");
    builder.CreateStore(ConstantInt::get(i1_ty, false), comparison_result,
                        true);
    // Check if the function has an sret attribute
    // opt says:
    // * Cannot have multiple 'sret' parameters!
    // * Attribute 'sret' is not on first or second parameter!
    Type *sretType;
    unsigned sretPos = std::numeric_limits<unsigned>::max();
    for (auto i : {0u, 1u}) {
      if ((sretType = original_function->getParamStructRetType(i))) {
        sretPos = i;
        break;
      }
    }
    SmallVector<Value *> args_vec;
    for (auto &arg : function->args()) {
      args_vec.push_back(&arg);
    }

    CallInst *cmp = nullptr;
    Value *return_value;
    Value *second_result_slot;
    if (sretType) {
      // For sret functions, we pass the original sret pointer to the first call
      // and only create a temporary alloca for the second call
      Value *sretAlloca2 = builder.CreateAlloca(sretType);

      SmallVector<Value *> args_vec_temp(args_vec);

      // Replace the sret argument for the second call with our temporary alloca
      args_vec_temp[sretPos] = sretAlloca2;

      auto *call1 = builder.CreateCall(original_function, args_vec);
      call1->setCallingConv(original_function->getCallingConv());
      call1->setAttributes(signature_attributes);

      auto *call2 = builder.CreateCall(original_function, args_vec_temp);
      call2->setCallingConv(original_function->getCallingConv());
      call2->setAttributes(signature_attributes);

      cmp = builder.CreateCall(cmp_function, {args_vec[sretPos], sretAlloca2});
      cmp->setCallingConv(cmp_function->getCallingConv());
      return_value = call1;
      second_result_slot = sretAlloca2;
    } else {
      auto *return_type = original_function->getReturnType();

      auto *return_var_1 = builder.CreateAlloca(return_type);
      auto *return_var_2 = builder.CreateAlloca(return_type);

      auto *call1 = builder.CreateCall(original_function, args_vec);
      call1->setCallingConv(original_function->getCallingConv());
      call1->setAttributes(signature_attributes);

      auto *call2 = builder.CreateCall(original_function, args_vec);
      call2->setCallingConv(original_function->getCallingConv());
      call2->setAttributes(signature_attributes);

      builder.CreateStore(call1, return_var_1);
      builder.CreateStore(call2, return_var_2);

      cmp = builder.CreateCall(cmp_function, {return_var_1, return_var_2});
      cmp->setCallingConv(cmp_function->getCallingConv());
      return_value = call1;
      second_result_slot = return_var_2;
    }
    cmp_function->setLinkage(GlobalValue::LinkageTypes::InternalLinkage);
    cmp_function->setComdat(nullptr);

    if (drop_function) {
      auto *drop = builder.CreateCall(drop_function, {second_result_slot});
      drop->setCallingConv(drop_function->getCallingConv());
      drop_function->setLinkage(GlobalValue::LinkageTypes::InternalLinkage);
      drop_function->setComdat(nullptr);
    }

    BasicBlock *return_block =
        BasicBlock::Create(function->getContext(), "return", function);
    BasicBlock *error_block =
        BasicBlock::Create(function->getContext(), "error", function);

    builder.CreateStore(cmp, comparison_result, true);
    auto *cmp_result = builder.CreateLoad(i1_ty, comparison_result, true);
    builder.CreateCondBr(cmp_result, return_block, error_block,
                         MDBuilder(Ctx).createBranchWeights(1, 2000));

    IRBuilder<> return_builder(return_block);
    if (return_value->getType()->isVoidTy()) {
      return_builder.CreateRetVoid();
    } else {
      return_builder.CreateRet(return_value);
    }

    IRBuilder<> error_builder(error_block);
    error_builder.CreateCall(
        Intrinsic::getOrInsertDeclaration(function->getParent(),
                                          Intrinsic::trap));
    error_builder.CreateUnreachable();
  }

  static Function *find_cmp_function(CallBase *identifier_call) {
    if (identifier_call->arg_size() == 0) {
      return nullptr;
    }
    return dyn_cast<Function>(
        identifier_call->getArgOperand(0)->stripPointerCastsAndAliases());
  }

  static Function *find_hardened_function(CallBase *identifier_call) {
    if (identifier_call->arg_size() < 2) {
      return nullptr;
    }
    return dyn_cast<Function>(
        identifier_call->getArgOperand(1)->stripPointerCastsAndAliases());
  }

  static bool has_drop_function(CallBase *identifier_call) {
    return identifier_call->arg_size() >= 3;
  }

  static Function *find_drop_function(CallBase *identifier_call) {
    return dyn_cast<Function>(
        identifier_call->getArgOperand(2)->stripPointerCastsAndAliases());
  }

  PreservedAnalyses run(Module &M, [[maybe_unused]] ModuleAnalysisManager &AM) {
    SmallVector<std::pair<Value *, StringRef>> hardening_requests;

    for (auto &function : M) {
      if (function.isDeclaration()) {
        continue;
      }
      for (auto &bb : function) {
        for (auto &inst : bb)
          if (auto *call = dyn_cast<CallBase>(&inst)) {
            if (auto *called_function = call->getCalledFunction()) {
              {
                auto called_name = called_function->getName();
                if (called_name.consume_front("internal_firv2_") and
                    called_name.consume_back("_identifier")) {
                  hardening_requests.push_back({call, called_name});
                  errs() << "Found function to harden: " << function.getName()
                         << "\n";
                }
              }
            }
          }
      }
    }
    for (auto &[hardening_request, IDX] : hardening_requests) {
      auto *call = cast<CallBase>(hardening_request);
      auto *function = find_hardened_function(call);
      if (!function) {
        M.getContext().emitError(
            "hardened function not found for: internal_firv2_" + IDX +
            "_identifier");
        continue;
      }
      if (function != call->getCaller()) {
        M.getContext().emitError("internal_firv2_" + IDX +
                                 "_identifier is called from " +
                                 call->getCaller()->getName() +
                                 ", but hardens " + function->getName());
        continue;
      }
      std::string original_name = function->getName().str();
      if (function->getReturnType()->isVoidTy() &&
          !function->hasStructRetAttr()) {
        errs() << "Skipping void function " << original_name << "\n";
        call->eraseFromParent();
        continue;
      }
      if (function->isVarArg()) {
        errs() << "Skipping variadic function " << original_name << "\n";
        call->eraseFromParent();
        continue;
      }
      Function *cmp_func = find_cmp_function(call);
      if (!cmp_func) {
        M.getContext().emitError("cmp function not found for: internal_firv2_" +
                                 IDX + "_identifier");
        continue;
      }
      if (cmp_func->isDeclaration()) {
        M.getContext().emitError("cmp function " + cmp_func->getName() +
                                 " has no body for: internal_firv2_" + IDX +
                                 "_identifier");
        continue;
      }
      auto *cmp_type = cmp_func->getFunctionType();
      bool is_cmp_signature = !cmp_type->isVarArg() &&
                              cmp_type->getReturnType()->isIntegerTy(1) &&
                              cmp_type->getNumParams() == 2 &&
                              cmp_type->getParamType(0)->isPointerTy() &&
                              cmp_type->getParamType(1)->isPointerTy();
      if (!is_cmp_signature) {
        M.getContext().emitError("cmp function " + cmp_func->getName() +
                                 " must have type i1 (ptr, ptr) for: "
                                 "internal_firv2_" +
                                 IDX + "_identifier");
        continue;
      }
      Function *drop_func = nullptr;
      if (has_drop_function(call)) {
        drop_func = find_drop_function(call);
        bool is_drop_function = drop_func && !drop_func->isDeclaration() &&
                                !drop_func->isVarArg() &&
                                drop_func->getReturnType()->isVoidTy() &&
                                drop_func->arg_size() == 1 &&
                                drop_func->getArg(0)->getType()->isPointerTy();
        if (!is_drop_function) {
          M.getContext().emitError(
              "drop function must be a defined void (ptr) function for: "
              "internal_firv2_" +
              IDX + "_identifier");
          continue;
        }
      }

      auto new_name = (original_name + ".original");
      function->setName(new_name);
      auto new_function = cast<Function>(
          M.getOrInsertFunction(original_name, function->getFunctionType())
              .getCallee());
      new_function->setLinkage(function->getLinkage());
      new_function->setVisibility(function->getVisibility());
      new_function->setDLLStorageClass(function->getDLLStorageClass());
      new_function->setComdat(function->getComdat());
      new_function->setCallingConv(function->getCallingConv());

      function->replaceUsesWithIf(new_function, [function](Use &use) {
        auto *user_call = dyn_cast<CallBase>(use.getUser());
        bool is_recursive_call = user_call && user_call->isCallee(&use) &&
                                 user_call->getFunction() == function;
        return !is_recursive_call;
      });
      build_function(new_function, function, cmp_func, drop_func);
      call->eraseFromParent();
    }
    if (hardening_requests.empty()) {
      return PreservedAnalyses::all();
    } else {
      return PreservedAnalyses::none();
    }
  }

  static bool isRequired() { return true; }
};
} // namespace

llvm::PassPluginLibraryInfo getFirv2PluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "firv2", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "firv2") {
                    MPM.addPass(Firv2{});
                    MPM.addPass(AlwaysInlinerPass());
                    return true;
                  }
                  if (Name == "firv2-internal") {
                    MPM.addPass(Firv2{});
                    return true;
                  }
                  return false;
                });
          }};
}
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getFirv2PluginInfo();
}
