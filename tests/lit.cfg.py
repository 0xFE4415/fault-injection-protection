import os
import shutil
import tomllib

import lit.util
import lit.formats

config.name = "LLVM"

config.test_format = lit.formats.ShTest()

config.suffixes = [".ll", ".c", ".test", ".yaml", ".rs"]

# test_source_root: The root path where tests are located.
config.test_source_root = os.path.dirname(__file__)

repo_root = os.path.dirname(config.test_source_root)
firv2_plugin = os.path.join(repo_root, "build", "lib", "LLVMFirv2.so")
firv2_macro_manifest = os.path.join(repo_root, "firv2", "rust-firv2", "Cargo.toml")
firv2_macro_target = os.path.join(config.test_source_root, "Output", "rust-firv2")
firv2_macro_debug = os.path.join(firv2_macro_target, "debug")

with open(os.path.join(repo_root, "rust-toolchain.toml.in"), "rb") as toolchain_file:
    rust_channel = tomllib.load(toolchain_file)["toolchain"]["channel"]

for variable in ["HOME", "RUSTUP_HOME", "CARGO_HOME"]:
    if variable in os.environ:
        config.environment[variable] = os.environ[variable]

if shutil.which("rustup"):
    config.available_features.add("rustup")

config.substitutions.append(
    (
        "%build_firv2_macro",
        f"cargo +{rust_channel} build -q --manifest-path {firv2_macro_manifest} "
        f"--target-dir {firv2_macro_target}",
    )
)
config.substitutions.append(
    (
        "%rustc_firv2",
        f"rustc +{rust_channel} --edition 2024 -C opt-level=3 -C embed-bitcode=yes "
        f"-C linker-plugin-lto -C link-arg=-fuse-ld=lld "
        f"-C link-arg=-Xlinker -C link-arg=--load-pass-plugin={firv2_plugin} "
        f'-C link-arg=-Xlinker "-Clink-arg=--lto-newpm-passes=lto<O3>,firv2" '
        f"--extern rust_firv2={firv2_macro_debug}/librust_firv2.so "
        f"-L dependency={firv2_macro_debug}/deps",
    )
)

cfip_plugin = os.path.join(repo_root, "build", "lib", "LLVMCfip.so")
cfip_macro_manifest = os.path.join(repo_root, "rust_attribute", "Cargo.toml")
cfip_macro_target = os.path.join(config.test_source_root, "Output", "rust-cfip")
cfip_macro_debug = os.path.join(cfip_macro_target, "debug")

config.substitutions.append(
    (
        "%build_cfip_macro",
        f"cargo +{rust_channel} build -q --manifest-path {cfip_macro_manifest} "
        f"--target-dir {cfip_macro_target}",
    )
)
config.substitutions.append(
    (
        "%rustc_cfip",
        f"rustc +{rust_channel} --edition 2024 -C opt-level=3 -C embed-bitcode=yes "
        f"-C linker-plugin-lto -C link-arg=-fuse-ld=lld "
        f"-C link-arg=-Xlinker -C link-arg=--load-pass-plugin={cfip_plugin} "
        f'-C link-arg=-Xlinker "-Clink-arg=--lto-newpm-passes=lto<O3>,cfip" '
        f"--extern cfip={cfip_macro_debug}/libcfip.so "
        f"-L dependency={cfip_macro_debug}/deps",
    )
)
