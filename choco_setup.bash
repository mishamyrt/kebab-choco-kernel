# Environment setup script for Choco Kernel (kebab)
# Copyright (C) 2021 Mikhael Khrustik <misha@myrt.co>
#
# This script must be *sourced* from a Bash in order to function.

# Check if $toolchain_path environment variable is set
if [ -z "$toolchain_path" ]; then
    echo "Toolchain path is not provided."
    echo "Please set \$toolchain_path environment variable."
    exit 1
else
    mkdir -p "$toolchain_path"
    mkdir -p release
fi

# Build config name
defconfig="choco_defconfig"

# Build display name in FKM
fkm_name="Choco 🍫 nightly"

# Main branch name
trunk_name="eleven"

# Threads count. Default equals the count of CPUs
threads="$(nproc)"

# Android LLVM Prebuilts version.
# Available versions can be viewed in the repository:
# https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/
llvm_revision="r407598"

# Internal part, don't edit. ↓
# Paths
_gcc32_dir="$toolchain_path/gcc32"
_gcc64_dir="$toolchain_path/gcc64"
_llvm_dir="$toolchain_path/llvm/clang-$llvm_revision"

export PATH="$_llvm_dir/bin:$_gcc64_dir/bin:$_gcc32_dir/bin:$PATH"
export LD_LIBRARY_PATH="$_llvm_dir/lib:$_llvm_dir/lib64:$LD_LIBRARY_PATH"

bootstrap_path="$PWD"

source helpers.bash
