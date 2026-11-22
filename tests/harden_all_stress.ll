; Stress test: harden-all must accept 100 fixed-seed llvm-stress modules of 5000 instructions.
; RUN: bash -c 'set -o pipefail; for seed in $(seq 1 100); do llvm-stress --seed=$seed --size=5000 | opt -passes="cfip<harden-all>" -load-pass-plugin=../build/lib/LLVMCfip.so -o /dev/null || { echo "failed on seed $seed" >&2; exit 1; }; done'
