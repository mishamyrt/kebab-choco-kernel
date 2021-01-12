# Build helpers for Choco Kernel
# Copyright (C) 2021 Mikhael Khrustik <misha@myrt.co>
#
# This script must be *sourced* from a Bash in order to function.

set -e

# Declare all side effects variables
_int_vars+=(
    _int_functions
	_out_dir
	_release_dir
	_flasher_dir
	_zip_file
	_arch
    _kmake_flags
)

# Declare all side-effects functions
_int_functions+=(
	croot
	log
	success
	clone_toolchain
	kmake
    kernel_build
    dtb_build
    regenerate_defconfig
    pack
    master_build
    publish
    unsetup
    _generate_changelog
    _generate_json
    _configure
    _local_version
    _get_repo
)

# Internal variables
_out_dir="$_bootstrap_path/out"
_release_dir="$_bootstrap_path/release"
_flasher_dir="$_bootstrap_path/flasher"
_zip_file="$_release_dir/${defconfig/_defconfig/}.zip"
_arch="arm64"

# Build flags
_kmake_flags=(
	-j"$threads"
	ARCH="$_arch"
	O="out"
    CC="clang"
    CLANG_TRIPLE="aarch64-linux-gnu-"
    CROSS_COMPILE="aarch64-linux-android-"
    CROSS_COMPILE_ARM32="arm-linux-androideabi-"
    AR="llvm-ar"
    NM="llvm-nm"
    OBJCOPY="llvm-objcopy"
    OBJDUMP="llvm-objdump"
    STRIP="llvm-strip"
)

# Go to kernel root directory
function croot() {
    cd $_bootstrap_path
}

# Print information message to CLI
function log() {
    echo -e "\e[90m$1\e[0m"
}

# Print success message to CLI
function success() {
    echo -e "\e[32m$1\e[0m"
}

# Download toolchain to $toolchain_path
function clone_toolchain() {
  _get_repo "$llvm_url"  "$_llvm_dir"
  _get_repo "$gcc32_url" "$_gcc32_dir"
  _get_repo "$gcc64_url" "$_gcc64_dir"
}

# Main wrapper for all `make` functions
function kmake() {
    make "${_kmake_flags[@]}" "$@"
}

# Build kernel image
function kernel_build() {
    kmake
    success "Kernel builded successfully"
}

# Build combined device tree
function dtb_build() {
    find "$_out_dir/arch/arm64/boot/dts/vendor/qcom" \
        -name '*.dtb' \
        -exec cat {} + > "$_out_dir/arch/arm64/boot/dtb"
    success "DTB builded successfully"
}

# Sync configuration file with tree
function regenerate_defconfig() {
    _configure
    cp -f "$_out_dir/defconfig" \
          "$_bootstrap_path/arch/$_arch/configs/$defconfig"
    success "defconfig saved successfully"
}

# Pack flashable archive from builded kernel and dtb
function pack() {
    cp -f $_out_dir/arch/arm64/boot/{Image.gz,dtb} "$_flasher_dir"
    rm -f "$_zip_file"
    cd "$_flasher_dir"
    zip -r9 $_zip_file *
    croot
    success "Flashable archive packed successfully"
}

# Full kernel pipeline
function master_build() {
    _configure
    kernel_build
    dtb_build
    pack
    success "Master pipeline completed successfully"
}

# Publish FKM build
function publish() {
    _generate_json
    _generate_changelog
    surge --project "$_release_dir" \
          -d "$surge_url" \
          --token "$surge_token"
}

# Unsetup Choco environment
function unsetup() {
    # Restore PATH
	export PATH="$_old_path"

	# Unset functions
	for func in "${_int_functions[@]}"; do
		unset -f "$func" > /dev/null 2>&1
	done

	# Unset variables
	for var in "${_int_vars[@]}"; do
		unset -v "$var" > /dev/null 2>&1
	done

    echo -e "\e[32mEnvironment successfully unsetuped\e[0m"
}

# Export git history to changelog
function _generate_changelog() {
    commit_count=50
    git log -n $commit_count \
        --pretty=format:'* %s' > "$_release_dir/changelog.txt"
    log "Changelog generated successfully"
}

# Generate FKM JSON file
function _generate_json() {
    hash="$(sha1sum $_zip_file | cut -d' ' -f1)"
    cat <<- EOF > "$_release_dir/index.html"
{
    "kernel": {
        "name": "$fkm_name",
        "sha1": "$hash",
        "link": "$surge_url/choco.zip",
        "version": "$(date '+%Y-%m-%d-%H-%M')$(_local_version)",
        "date": "$(date '+%Y-%m-%d')",
        "changelog_url": "$surge_url/changelog.txt"
    },
    "support": {
        "link": "https://github.com/mishamyrt/kebab-choco-kernel/issues"
    }
}
EOF
    log "Release JSON generated successfully"
}

# Generate defconfig
function _configure() {
    kmake "$defconfig"
    kmake savedefconfig
    log "defconfig generated successfully"
}

# Format build local version
function _local_version() {
    branch="$(git rev-parse --abbrev-ref HEAD)"
    local_version="${branch/upstream\//}"
    local_version="${local_version/\//-}"
    local_version="${local_version/$trunk_name/}"
    if (("${#local_version}" > 0)); then
        if [[ ${local_version:0:1} != "-" ]]; then
            local_version="-$local_version"
        fi
    fi
    echo $local_version
}

# Shallow clone
function _get_repo() {
    if [ -d "$2" ]; then
        cd $2
        if git rev-parse --git-dir 2> /dev/null; then
            log "$1 already downloaded"
            croot
        else
            croot
            rm -rf "$2"
            git clone -j"$threads" --depth=1 "$1" "$2"
        fi
    else
        git clone -j"$threads" --depth=1 "$1" "$2"
    fi
}