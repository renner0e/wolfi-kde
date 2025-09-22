export MELANGE_IMAGE := env("MELANGE_IMAGE", "cgr.dev/chainguard/melange:latest")
export SIGNING_KEY_PATH := env("SIGNING_KEY_PATH", "melange.rsa")
export MELANGE_RUNNER := env("MELANGE_RUNNER", "bubblewrap")
export PACKAGES_DIR := env("PACKAGES_DIR", "manifests")
export MELANGE_OPTS := "
    -i
    --debug
    --log-level=DEBUG
    --arch host
    --pipeline-dir ./pipelines
    --repository-append https://packages.wolfi.dev/os
    --keyring-append https://packages.wolfi.dev/os/wolfi-signing.rsa.pub"
export APKO_OPTS := "
    --repository-append https://packages.wolfi.dev/os
    --keyring-append https://packages.wolfi.dev/os/wolfi-signing.rsa.pub"

create-cache-dir:
    mkdir -p ./.cache/apk-cache
    mkdir -p ./.cache/melange
    mkdir -p ./.cache/workspace

keygen *$ARGS:
    podman run --rm -it -v "${PWD}:/work:Z" -w /work \
        "${MELANGE_IMAGE}" \
        keygen $ARGS

build $package="":
    just create-cache-dir
    melange build $MELANGE_OPTS "${PACKAGES_DIR}/${package}.yaml" \
        --source-dir "./${PACKAGES_DIR}/${package}" \
        --repository-append "./packages" \
        --keyring-append "./${SIGNING_KEY_PATH}.pub" \
        --signing-key "./${SIGNING_KEY_PATH}" \
        --apk-cache-dir "./.cache/apk-cache" \
        --cache-dir "./.cache/melange/${package}" \
        --workspace-dir "./.cache/workspace/${package}" \
        --runner "${MELANGE_RUNNER}"

qt:
  just build xcb-util-cursor # I do not want an xorg session, libplasma doesn't build without it
  just build qt6-qtbase # I do not want to have this, needs wayland and vulkan flags
  just build qt6-qtshadertools
  just build qt6-qtsvg
  just build qt6-qtdeclarative
  just build qt6-qtimageformats
  just build qt6-qtwayland
  just build qt6-qttools
  just build qt6-qtsensors
  just build qt6-qtconnectivity
  just build qt6-qtwebsockets
  #just build qt6-qthttpserver
  just build qt6-qtwebchannel
  just build qt6-qtremoteobjects
  just build qt6-qtquicktimeline

  just build minizip-ng
  just build assimp

  just build jsoncpp # I do not want to have this, build flag shenanigans
  just build openxr
  just build qt6-qtquick3d

  just build qt6-qt3d
  just build qt6-qt5compat
  just build qt6-qtpositioning
  just build qt6-qtlocation

  just build qt6-qtnetworkauth
  just build qt6-qtlanguageserver

  just build fdk-aac
  just build ldacbt
  just build libcamera
  just build libcanberra
  just build libfreeaptx
  just build liblc3
  just build cunit
  just build libmysofa
  just build serd
  just build zix
  just build sord
  just build lv2
  just build srantom
  just build lilv
  just build webrtc-audio-processing
  just build pipewire
  just build qt6-qtmultimedia
  #just build qt6-qtdatavis3d

  just build qt6-qtspeech
  just build qt6-qtcharts
  just build qt6-qtscxml
  just build qt6-qtdoc
  just build qt6-qtgraphs

  just build libvpx
  #just build qt6-qtwebengine

kde:
  just build extra-cmake-modules
  just build libxmlb
  just build snowball
  just build appstream

  just build plasma-wayland-protocols

  just build kf6-breeze-icons
  just build kf6-karchive
  just build kf6-kcoreaddons
  just build kf6-ki18n
  just build kf6-kconfig
  just build kf6-kwidgetsaddons
  just build kf6-kcodecs
  just build kf6-kdbusaddons
  just build kf6-kguiaddons
  just build kf6-kwindowsystem
  just build kf6-kitemviews

  just build kf6-kfilemetadata
  just build polkit-qt-1
  just build kf6-kauth

  just build libraw
  # TODO: remove libjxl this is in wolfi now
  #just build libjxl
  just build kf6-kimageformats

  just build kf6-ktexttemplate

build-tree:
    echo "This will build all packages required for Wolfi Bootc"
    just build composefs
    just build ostree
    just build bootc
    just build bootupd

    just build composefs-rs
    just build dracut

    just build py3-pefile
    just build systemd
    just build kernel
    just build kernel-initramfs
    just build kernel-uki

renovate:
    #!/usr/bin/env bash
    GITHUB_COM_TOKEN=$(cat ~/.ssh/gh_renovate) LOG_LEVEL=${LOG_LEVEL:-debug} renovate --platform=local

build-containerfile:
    sudo podman build \
        -t wolfi-bootc:latest .

build-apko $yaml="apko.yaml" $tag="wolfi-bootc:latest":
    mkdir -p ./output/oci
    apko build $APKO_OPTS \
        --repository-append "./packages" \
        --keyring-append "./${SIGNING_KEY_PATH}.pub" \
        --sbom-path ./output/oci \
        "${yaml}" "${tag}" ./output/oci/
    sudo skopeo copy oci:./output/oci/ containers-storage:${tag}

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v .:/data:Z \
        --security-opt label=type:unconfined_t \
        wolfi-bootc:latest bootc {{ARGS}}

generate-bootable-image:
    #!/usr/bin/env bash
    if [ ! -e ./bootable.img ] ; then
        fallocate -l 20G bootable.img
    fi
    just bootc install to-disk --composefs-native --via-loopback /data/bootable.img --filesystem ext4 --wipe --bootloader systemd-boot
