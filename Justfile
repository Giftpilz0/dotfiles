export bib_image := env('BIB_IMAGE', 'quay.io/centos-bootc/bootc-image-builder:latest')
export default_tag := env('DEFAULT_TAG', 'latest')
export image_name := env('IMAGE_NAME', 'ublue-niri')

[private]
default:
    @just --list

# ----------------------
# Container Image Management
# ----------------------

[group('Container Image')]
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail
    BUILD_ARGS=()
    if [[ -z "$(git status -s 2>/dev/null)" ]]; then
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
    set -euo pipefail
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

# ----------------------
# Utility
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
