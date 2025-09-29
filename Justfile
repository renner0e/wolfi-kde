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

appstream:
  just build libxmlb
  just build snowball
  just build appstream

pw:
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

nm:
  just build libmbim
  just build libqrtr-glib
  just build libqmi
  just build ModemManager
  just build libndp
  just build mobile-broadband-provider-info
  just build newt
  just build NetworkManager


# build this before doing qt
qt-deps:
  just build xcb-util-cursor # I do not want an xorg session, libplasma doesn't build without it
  just build minizip-ng
  just build assimp

  just build jsoncpp # I do not want to have this, build flag shenanigans
  just build openxr


qt:
  just build qt5-qtbase # needs fixes or else it conflicts with qmake with qt6
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

  just build qt6-qtquick3d

  just build qt6-qt3d
  just build qt6-qt5compat
  just build qt6-qtpositioning
  just build qt6-qtlocation

  just build qt6-qtnetworkauth
  just build qt6-qtlanguageserver


  just build qt6-qtmultimedia
  #just build qt6-qtdatavis3d

  just build qt6-qtspeech
  just build qt6-qtcharts
  just build qt6-qtscxml
  just build qt6-qtdoc
  just build qt6-qtgraphs

  #just build libvpx
  #just build qt6-qtwebengine

# dependencies are all in wolfi, build this first
deps1:
  just build extra-cmake-modules # for fucking everything
  just build plasma-wayland-protocols

  # prison
  just build libqrencode
  just build stb
  just build zxing-cpp

  # kwallet
  just build gpgmepp

  # kio
  just build libgudev
  just build switcheroo-control

  # kimageformats
  just build libraw

  # kwin and plasma-desktop
  just build libdisplay-info
  just build libei

  # plasma-desktop
  just build exiv2
  just build libqalculate

  # libaccounts-qt -> kaccounts
  just build libaccounts-glib

  # appmenu-gtk-module
  #just build libwnck

  # plasma-desktop
  just build libwacom

  # kio-extras
  #just build gsettings-desktop-schemas

# depend on qt stuff
deps2:
  # kauth
  just build polkit-qt-1

  # syntax highlighting
  just build xerces-c

  # kwallet
  just build qca

  # plasma-workspace
  just build qcoro
  # build with qt support
  just build poppler

  just build phonon

  just build libaccounts-qt
  just build signond

  #just build libproxy

kf:
  just kf-t1
  just kf-t2
  just kf-t3
  just kf-t4

# dependencies on qt
kf-t1:
  just build kf6-attica
  just build kf6-breeze-icons
  just build kf6-karchive
  just build kf6-kcodecs
  just build kf6-kconfig
  just build kf6-kcoreaddons
  just build kf6-kdbusaddons
  just build kf6-kglobalaccel
  just build kf6-kguiaddons
  just build kf6-kholidays
  just build kf6-ki18n
  just build kf6-kidletime
  just build kf6-kirigami
  just build kf6-kitemmodels
  just build kf6-kitemviews
  just build kf6-kquickcharts
  just build kf6-ktexttemplate
  just build kf6-kunitconversion
  just build kf6-kwidgetsaddons
  just build kf6-kwindowsystem
  just build kf6-networkmanager-qt
  just build kf6-prison
  just build kf6-solid
  just build kf6-sonnet
  just build kf6-syntax-highlighting

# dependencies on tier1
kf-t2:
  just build kf6-kauth
  just build kf6-kbookmarks
  just build kf6-kcolorscheme
  just build kf6-kcompletion
  just build kf6-kcrash
  just build kf6-kdeclarative
  just build kf6-kdoctools
  just build kf6-kfilemetadata
  just build kf6-kimageformats
  just build kf6-kirigami-addons
  just build kf6-knotifications
  just build kf6-kpackage
  just build kf6-kpty
  just build kf6-krunner
  just build kf6-kstatusnotifieritem
  just build kf6-ksvg
  just build kf6-kuserfeedback
  just build kf6-syndication

kf-t3:
  just build kf6-kconfigwidgets
  just build kf6-kded
  just build kf6-kdesu
  just build kf6-kiconthemes
  just build kf6-kjobwidgets
  just build kf6-knewstuff
  just build kf6-kservice
  just build kf6-kwallet
  just build kf6-kxmlgui
  just build kf6-qqc2-desktop-style

kf-t4:
  just build kf6-kio
  just build kf6-frameworkintegration
  just build kf6-baloo
  just build kf6-kcmutils
  just build kf6-knotifyconfig
  just build kf6-kparts
  just build kf6-ktexteditor
  just build kf6-ktextwidgets

kde:
  just build libkexiv2-qt
  just build kdecoration
  just build plasma-activities
  just build plasma-activities-stats
  just build kpipewire
  just build kdecoration
  just build kwayland
  just build plasma5support
  just build kglobalacceld
  just build knighttime
  just build layer-shell-qt
  just build libkscreen
  just build libplasma
  just build kscreenlocker
  just build kscreen
  just build libqaccessibilityclient
  just build plasma-breeze
  just build kwin
  just build libksysguard
  just build plasma-workspace
  just build kaccounts-integration

  #just build plasma-desktop

world: deps1 pw qt-deps qt deps2 appstream nm kf kde

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
