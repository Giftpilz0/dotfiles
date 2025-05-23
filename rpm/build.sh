#!/bin/bash

# Package list in build order
packages=(
    "hyprutils"
    "hyprlang"
    "hyprgraphics"
    "hyprland-protocols"
    "hyprwayland-scanner"
    "hyprland-qt-support"
    "hypridle"
    "hyprlock"
    "hyprpaper"
    "hyprpolkitagent"
    "eww-git"
    "matugen-git"
    "yolk-git"
    "xwayland-satellite-git"
    "waypipe-git"
    "niri"
)

# Required host tools
required_tools=("mock" "rpmdevtools" "dnf-plugins-core")

# Working directory and structure
workdir="$(pwd)"
rpmbuild_top="$workdir/rpmbuild"
out_dir="$workdir/out"
srpms_dir="$out_dir/srpms"
rpms_dir="$out_dir/rpms"
repo_dir="$out_dir/repo"
mock_config="fedora-$(rpm -E '%fedora')-x86_64"
mock_result_dir="$repo_dir/results/$mock_config"

# Cleanup function
cleanup() {
    echo -e "\n======================================="
    echo "Cleaning Up Temporary Directories"
    echo "======================================="
    if [[ -d "$rpmbuild_top" ]]; then
        rm -rf "$rpmbuild_top"
        echo "[✔] Removed temporary rpmbuild directory."
    fi
    if [[ -d "$repo_dir" ]]; then
        rm -rf "$repo_dir"
        echo "[✔] Removed temporary repository directory."
    fi
}

# Clean repo directory function
clean_repo_directory() {
    echo -e "\nCleaning up repository directory..."
    if [[ -d "$repo_dir" ]]; then
        rm -rf "$repo_dir"
        echo "[✔] Repository directory cleaned."
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

check_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

setup_directories() {
    echo -e "\nSetting up build directories..."

    # Clean and create rpmbuild directory
    rm -rf "$rpmbuild_top"
    mkdir -p "$rpmbuild_top"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    # Clean and create output directory structure
    rm -rf "$out_dir"
    mkdir -p "$srpms_dir" "$rpms_dir" "$repo_dir"

    echo "[✔] Build directories created:"
    echo "    • SRPMs: $srpms_dir"
    echo "    • RPMs: $rpms_dir"
    echo "    • Repo: $repo_dir"
}

copy_spec_files() {
    echo -e "\nCopying spec files..."
    for pkg in "${packages[@]}"; do
        if [[ -f "$workdir/SPECS/$pkg/$pkg.spec" ]]; then
            cp "$workdir/SPECS/$pkg/$pkg.spec" "$rpmbuild_top/SPECS/"
            echo "[✔] Copied spec for $pkg"
        else
            echo "[✘] Spec file not found for $pkg"
            exit 1
        fi
    done
}

copy_patch_files() {
    echo -e "\nCopying patch files..."
    patch_count=0
    for pkg in "${packages[@]}"; do
        spec_pkg_dir="$workdir/SPECS/$pkg"
        if [[ -d "$spec_pkg_dir" ]]; then
            for patch_file in "$spec_pkg_dir"/*.{patch,diff,patch.gz,diff.gz,patch.bz2,diff.bz2,patch.xz,diff.xz}; do
                if [[ -f "$patch_file" ]]; then
                    cp "$patch_file" "$rpmbuild_top/SOURCES/"
                    echo "[✔] Copied patch: $(basename "$patch_file")"
                    ((patch_count++))
                fi
            done
        fi
    done

    if [[ $patch_count -eq 0 ]]; then
        echo "[✔] No patch files found."
    else
        echo "[✔] Copied $patch_count patch files."
    fi
}

build_srpms() {
    echo -e "\nBuilding source RPMs..."
    for spec in "$rpmbuild_top"/SPECS/*.spec; do
        pkg_name=$(basename "$spec" .spec)
        if rpmbuild \
            --define "_topdir $rpmbuild_top" \
            --undefine _disable_source_fetch \
            -bs "$spec" >/dev/null 2>&1; then
            echo "[✔] Successfully built SRPM for $pkg_name"
        else
            echo "[✘] Failed to build SRPM for $pkg_name"
            exit 1
        fi
    done
}

collect_srpms() {
    echo -e "\nCollecting SRPMs..."
    if cp "$rpmbuild_top"/SRPMS/*.src.rpm "$srpms_dir"/ 2>/dev/null; then
        echo "[✔] SRPMs collected in $srpms_dir"

        # Also copy to repo directory for mock to use
        cp "$srpms_dir"/*.src.rpm "$repo_dir"/ 2>/dev/null
        echo "[✔] SRPMs copied to repo directory"
    else
        echo "[✘] Failed to collect SRPMs."
        exit 1
    fi
}

build_with_mock() {
    for pkg in "${packages[@]}"; do
        echo -e "\nBuilding $pkg with mock..."

        if mock \
            --root "$mock_config" \
            --enable-network \
            --localrepo "$repo_dir" \
            --chain \
            "$repo_dir/${pkg}"*.src.rpm >/dev/null 2>&1; then
            echo "[✔] Successfully built $pkg"

            # Copy RPMs and logs from mock result directory
            copy_mock_results "$pkg"
        else
            echo "[✘] Failed to build $pkg"
            exit 1
        fi
    done
}

copy_mock_results() {
    local pkg="$1"
    echo "    Collecting results for $pkg..."

    # Copy RPMs
    if [[ -d "$mock_result_dir" ]]; then
        # Copy binary RPMs (exclude SRPMs, debuginfo, and debugsource)
        find "$mock_result_dir" -name "${pkg}*.rpm" ! -name "*.src.rpm" ! -name "*debuginfo*" ! -name "*debugsource*" -type f -exec cp {} "$rpms_dir"/ \; 2>/dev/null

        # Copy any devel packages (also excluding debuginfo and debugsource)
        find "$mock_result_dir" -name "${pkg}-devel*.rpm" ! -name "*debuginfo*" ! -name "*debugsource*" -type f -exec cp {} "$rpms_dir"/ \; 2>/dev/null

        echo "    [✔] Results collected for $pkg"
    else
        echo "    [✘] Mock result directory not found: $mock_result_dir"
    fi
}

echo "======================================="
echo "RPM Build Script"
echo "======================================="
echo "Working in: $workdir"
echo "Mock config: $mock_config"

echo -e "\n======================================="
echo "Checking and Installing Required Tools"
echo "======================================="
for tool in "${required_tools[@]}"; do
    if check_installed "$tool"; then
        echo "[✔] $tool is already installed."
    else
        echo "[✘] $tool is not installed. Installing..."
        if sudo dnf install -y "$tool" >/dev/null 2>&1; then
            echo "[✔] Successfully installed $tool."
        else
            echo "[✘] Failed to install $tool."
            exit 1
        fi
    fi
done

echo -e "\n======================================="
echo "Setting Up Build Environment"
echo "======================================="
setup_directories
copy_spec_files
copy_patch_files

echo -e "\n======================================="
echo "Building Source RPMs"
echo "======================================="
build_srpms
collect_srpms

echo -e "\n======================================="
echo "Building with Mock"
echo "======================================="
build_with_mock

echo -e "\n======================================="
echo "Cleaning Up"
echo "======================================="
clean_repo_directory

echo -e "\n======================================="
echo "Build Completed Successfully"
echo "======================================="
echo "[✔] Build results:"
echo "    • SRPMs: $srpms_dir"
echo "    • RPMs: $rpms_dir"
echo ""
echo "To install built packages:"
echo "    sudo dnf install $rpms_dir/*.rpm"
