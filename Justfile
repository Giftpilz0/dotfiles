# --------------------------------------------------------------------
# Variables (can be overridden with environment variables)
# --------------------------------------------------------------------

export bib_image := env('BIB_IMAGE', 'quay.io/centos-bootc/bootc-image-builder:latest')
export default_tag := env('DEFAULT_TAG', 'latest')
export image_name := env('IMAGE_NAME', 'ublue-niri')
export ansible_user := env('ANSIBLE_USER', 'root')
export inventory := env('INVENTORY', 'inventory/workstation')

[private]
default:
    @just --list

# ----------------------
# Utility Helper Commands
# ----------------------

[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# -------------------------
# Container Image Management
# -------------------------

[group('Container Image')]
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    BUILD_ARGS=()
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi
    podman build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "${target_image}:${tag}" \
        --file ublue-niri/Containerfile \
        .

[private]
_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root — rootful storage is up to date."
        exit 0
    fi
    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
    set +e
    ROOT_IMG_ID=$(just sudoif podman images --filter "reference=${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
    set -e
    if [[ -n "$USER_IMG_ID" ]]; then
        if [[ "$ROOT_IMG_ID" != "$USER_IMG_ID" ]]; then
            echo "Copying image to rootful storage..."
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        else
            echo "Rootful image ID matches — no copy needed."
        fi
    else
        echo "Image not found locally — pulling from registry..."
        just sudoif podman pull "${target_image}:${tag}"
    fi

# ------------------
# Bootable Disk Images
# ------------------

[private]
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail
    args="--type ${type} "
    args+="--use-librepo=True "
    args+="--rootfs=btrfs"
    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)
    sudo podman run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/ublue-niri/${config}:/config.toml:ro \
      -v $BUILDTMP:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${target_image}:${tag}"
    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

[private]
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

[group('Disk Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "iso" "disk_config/iso.toml")

[group('Disk Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "iso" "disk_config/iso.toml")

# ----------------------------
# Ansible Environment Provision
# ----------------------------

[group('Ansible')]
ansible-bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail

    cd ansible/

    echo "======================================="
    echo "Checking and Installing Missing Packages"
    echo "======================================="

    packages=(ansible python3-rpm git-core tar python3-dnf)
    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            echo "[✔] $pkg is already installed."
        else
            echo "[✘] $pkg is not installed. Installing..."
            sudo dnf install -y "$pkg" || { echo "[✘] Failed to install $pkg."; exit 1; }
            echo "[✔] Successfully installed $pkg."
        fi
    done

    echo "======================================="
    echo "Installing Required Ansible Collections"
    echo "======================================="

    collections=(
        "git+https://github.com/Giftpilz0/ansible-collection-general.git"
        "git+https://github.com/Giftpilz0/ansible-collection-server.git"
    )
    for collection in "${collections[@]}"; do
        echo "Installing collection: $collection..."
        ansible-galaxy collection install "$collection" || { echo "[✘] Failed to install $collection."; exit 1; }
        echo "[✔] Successfully installed $collection."
    done

    echo -e "\n======================================="
    echo "Executing Ansible Playbook"
    echo "======================================="
    if ansible-playbook --connection=local -i "${inventory}" "play.yml" --extra-vars "ansible_user=${ansible_user}"; then
        echo -e "\n[✔] Playbook executed successfully."
    else
        echo -e "\n[✘] Playbook execution failed. Please check the playbook and logs for details."
        exit 1
    fi

    echo -e "\n[✔] Ansible provisioning complete."

# ----------------
# Yolk Deployment
# ----------------

[group('Yolk')]
yolk-deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    # Directories to clean up
    dirs=(
      "$HOME/.bashrc"
      "$HOME/.bashrc.d"
      "$HOME/.config/DankMaterialShell"
      "$HOME/.config/dgop"
      "$HOME/.config/gtk-3.0"
      "$HOME/.config/gtk-4.0"
      "$HOME/.config/helix"
      "$HOME/.config/kitty"
      "$HOME/.config/matugen"
      "$HOME/.config/niri"
      "$HOME/.config/quickshell"
      "$HOME/.config/vim"
      "$HOME/.config/wofi"
      "$HOME/.config/xdg-desktop-portal"
      "$HOME/.var/app/dev.zed.Zed/config/zed"
      "$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
      "$HOME/.inputrc"
    )

    # Systemd services to enable & start
    services=(ssh-agent)

    echo
    echo "======================================="
    echo "DankMaterialShell (dms) configuration"
    echo "======================================="
    read -r -p "Do you want to use DankMaterialShell (dms)? [y/N]: " use_dms
    use_dms=${use_dms,,}

    config_file="eggs/niri/config.kdl"

    if [[ "$use_dms" == "y" || "$use_dms" == "yes" ]]; then
        enable_dms=true
        services+=(dms)
        services+=(dsearch)
        sed -i '/misc\/dms\.kdl/s/^\/\/* *//; /misc\/nodms\.kdl/s/^ *\(\/\/*\)* */\/\/ /' "$config_file"
    else
        enable_dms=false
        sed -i '/misc\/dms\.kdl/s/^ *\(\/\/*\)* */\/\/ /; /misc\/nodms\.kdl/s/^\/\/* *//g' "$config_file"
    fi

    # echo -e "\n======================================="
    # echo "Installing yolk-git from COPR repository"
    # echo "======================================="

    # # Check if we're running as root
    # if [[ $EUID -ne 0 ]]; then
    #     echo "[!] Script is not running as root, skipping package installation"
    #     echo "[!] Please run with 'sudo' to install packages"
    # else
    #     echo "[✔] Enabling COPR repository giftpilz0/misc"
    #     if dnf copr enable -y giftpilz0/misc >/dev/null 2>&1; then
    #         echo "[✔] COPR repository giftpilz0/misc enabled successfully"

    #         echo "[✔] Installing yolk-git from COPR"
    #         if dnf install -y yolk-git >/dev/null 2>&1; then
    #             echo "[✔] yolk-git installed successfully"
    #         else
    #             echo "[✘] Failed to install yolk-git"
    #         fi
    #     else
    #         echo "[✘] Failed to enable COPR repository giftpilz0/misc"
    #     fi

    #     if [[ "$enable_dms" == true ]]; then
    #         echo
    #         echo "======================================="
    #         echo "Installing dms from COPR repository"
    #         echo "======================================="

    #         echo "[✔] Enabling COPR repository avengemedia/dms"
    #         if dnf copr enable -y avengemedia/dms >/dev/null 2>&1; then
    #             echo "[✔] COPR repository avengemedia/dms/ enabled successfully"

    #             echo "[✔] Installing dms from COPR"
    #             if dnf install -y dms >/dev/null 2>&1; then
    #                 echo "[✔] dms installed successfully"
    #             else
    #                 echo "[✘] Failed to install dms"
    #             fi
    #         else
    #             echo "[✘] Failed to enable COPR repository avengemedia/dms"
    #         fi
    #     fi
    # fi

    echo -e "\n======================================="
    echo "Cleaning old dotfiles directories and files"
    echo "======================================="
    for d in "${dirs[@]}"; do
      if [ -L "$d" ]; then
        echo "[✔] Unlinking symlink $d"
        unlink "$d"
      elif [ -d "$d" ]; then
        echo "[✔] Removing directory $d"
        rm -rf "$d"
      elif [ -f "$d" ]; then
        echo "[✔] Removing file $d"
        rm -f "$d"
      else
        echo "[✘] Skipping $d (not present or not a directory/symlink/file)"
      fi
    done

    echo -e "\n======================================="
    echo "Running yolk sync"
    echo "======================================="
    if yolk sync >/dev/null 2>&1; then
      echo "[✔] yolk sync completed successfully"
    else
      echo "[✘] yolk sync completed with warnings"
    fi

    echo -e "[✔] Listing installed packages\n"
    yolk list

    echo -e "\n======================================="
    echo "Setting up systemd user services"
    echo "======================================="
    for svc in "${services[@]}"; do
      echo "[✔] Enabling & starting $svc.service"
      if systemctl --user enable --now "$svc.service" >/dev/null 2>&1; then
        echo -e "[✔] $svc.service is now running\n"
      else
        echo -e "[✘] Failed to enable/start $svc.service\n"
        exit 1
      fi
    done

    echo -e "\n======================================="
    echo "Dotfiles installation complete"
    echo "======================================="
