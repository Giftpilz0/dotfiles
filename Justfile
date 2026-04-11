export bib_image := env('BIB_IMAGE', 'quay.io/centos-bootc/bootc-image-builder:latest')
export image_name := env('IMAGE_NAME', 'fedora-bootc-niri')
export image_tag := env('IMAGE_TAG', 'latest')
export image_ref := env('IMAGE_FULL', 'localhost/' + image_name + ':' + image_tag)
export mkosi_dir := env('MKOSI_DIR', 'fedora-bootc-niri')
export ujust_bundle_dir := mkosi_dir + '/mkosi.extra/usr/share/ujust'
export build_repo_dir := mkosi_dir + '/mkosi.extra/usr/share/factory/dotfiles-repo'

default:
    @just --list

config:
    cd "{{ mkosi_dir }}" && PAGER=cat mkosi --debug cat-config

build:
    #!/usr/bin/env bash
    set -euo pipefail
    just _prepare-build
    cd "{{ mkosi_dir }}"
    rm -rf mkosi.output
    rm -f mkosi.version
    mkosi -B --debug --force

clean:
    #!/usr/bin/env bash
    set -euo pipefail
    paths=(
        "{{ mkosi_dir }}/mkosi.output"
        "{{ mkosi_dir }}/mkosi.cache"
        "{{ mkosi_dir }}/mkosi.tools"
        "{{ mkosi_dir }}/mkosi.tools.manifest"
        "{{ ujust_bundle_dir }}"
        "{{ build_repo_dir }}"
        output
    )
    if ! rm -rf "${paths[@]}" 2>/dev/null; then
        sudo rm -rf "${paths[@]}"
    fi
    if ! rm -f "{{ mkosi_dir }}/mkosi.version" 2>/dev/null; then
        sudo rm -f "{{ mkosi_dir }}/mkosi.version"
    fi

load:
    #!/usr/bin/env bash
    set -euo pipefail
    OUTPUT_DIR="{{ mkosi_dir }}/mkosi.output"
    LATEST=$(find "${OUTPUT_DIR}" -maxdepth 1 \( -type f -o -type d \) -name "{{ image_name }}_*" ! -name "*.manifest" ! -name "*.vmlinuz" | sort | tail -n1)
    if [[ -z "${LATEST}" ]]; then
        echo "No mkosi output found. Run 'just build' first." >&2
        exit 1
    fi
    IMAGE_ID=$(podman load -i "${LATEST}" -q | cut -d: -f3)
    podman tag "${IMAGE_ID}" "{{ image_ref }}"
    if ! podman image inspect "{{ image_ref }}" 2>/dev/null | grep -q '"containers.bootc":[[:space:]]*"1"'; then
        CID=$(podman create "{{ image_ref }}" /bin/true)
        trap 'podman rm -f "${CID}" >/dev/null 2>&1 || true' EXIT
        podman commit --change 'LABEL containers.bootc=1' "${CID}" "{{ image_ref }}" >/dev/null
        podman rm -f "${CID}" >/dev/null
        trap - EXIT
    fi
    echo "Tagged {{ image_ref }}"

lint:
    podman run --rm -it --entrypoint=bootc "{{ image_ref }}" container lint

rebuild: clean build load lint

[private]
_prepare-build:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 "{{ mkosi_dir }}/render_mkosi.py"
    REPO_ROOT=$(git rev-parse --show-toplevel)
    rm -rf "{{ ujust_bundle_dir }}" "{{ build_repo_dir }}"
    install -d "{{ ujust_bundle_dir }}" "{{ build_repo_dir }}"
    rsync -a --delete \
        "${REPO_ROOT}/ansible" \
        "${REPO_ROOT}/install-justfiles.sh" \
        "${REPO_ROOT}/just" \
        "{{ ujust_bundle_dir }}/"
    rsync -a --delete \
        --exclude '.git' \
        --exclude '.ansible' \
        --exclude 'fedora-bootc-niri/mkosi.cache' \
        --exclude 'fedora-bootc-niri/mkosi.output' \
        --exclude 'fedora-bootc-niri/mkosi.tools' \
        --exclude 'fedora-bootc-niri/mkosi.tools.manifest' \
        --exclude 'fedora-bootc-niri/.mkosi-private' \
        --exclude 'fedora-bootc-niri/mkosi.version' \
        --exclude 'output' \
        "${REPO_ROOT}/" \
        "{{ build_repo_dir }}/"

[private]
_ensure-rootful-image:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! podman image exists "{{ image_ref }}"; then
        if [[ "{{ image_ref }}" == localhost/* ]]; then
            OUTPUT_DIR="{{ mkosi_dir }}/mkosi.output"
            if ! find "${OUTPUT_DIR}" -maxdepth 1 \( -type f -o -type d \) -name "{{ image_name }}_*" ! -name "*.manifest" ! -name "*.vmlinuz" | grep -q .; then
                just build
            fi
            just load
        else
            podman pull "{{ image_ref }}"
        fi
    fi
    if sudo podman image exists "{{ image_ref }}"; then
        exit 0
    fi
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "${TMPDIR}"' EXIT
    podman save -o "${TMPDIR}/image.tar" "{{ image_ref }}"
    sudo podman load -i "${TMPDIR}/image.tar"

installer-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    BUILDTMP=$(mktemp -d -p "${PWD}" -t _build-bib.XXXXXXXXXX)
    trap 'sudo rm -rf "${BUILDTMP}"' EXIT
    just _ensure-rootful-image
    sudo podman run \
        --rm \
        -it \
        --privileged \
        --pull=newer \
        --net=host \
        --security-opt label=type:unconfined_t \
        -v "$(pwd)/fedora-bootc-niri/disk_config/iso.toml:/config.toml:ro" \
        -v "${BUILDTMP}:/output" \
        -v "/var/lib/containers/storage:/var/lib/containers/storage" \
        "{{ bib_image }}" \
        --type iso \
        --rootfs btrfs \
        --use-librepo=True \
        "{{ image_ref }}"
    mkdir -p output
    sudo mv -f "${BUILDTMP}"/* output/
    sudo chown -R "${USER}:${USER}" output/

rebuild-installer-iso:
    just build
    just load
    just installer-iso
