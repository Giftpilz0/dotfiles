%bcond_without check

# prevent library files from being installed
%global __cargo_is_lib() 0

%global crate niri
%global version 25.05
%global url https://github.com/YaLTeR/niri

%global commit ae89cb6017668f3a81ccd92461cbbc70ab8377d0
%global shortcommit %(c=%{commit}; echo ${c:0:7})

# We want panic backtraces to work without installing the debuginfo package,
# so we leave the debuginfo in the main binary.
%global debug_package %{nil}
%global __strip /bin/true

# To reduce the file size, do some convincing of rust-srpm-macros
# to leave alone the chosen debug settings from Cargo.toml.
%global rustflags_debuginfo please-remove-me
%global build_rustflags %{shrink:
  -Copt-level=%rustflags_opt_level
  -Ccodegen-units=%rustflags_codegen_units
  -Cstrip=none
  %{expr:0%{?_include_frame_pointers} && ("%{_arch}" != "ppc64le" && "%{_arch}" != "s390x" && "%{_arch}" != "i386") ? "-Cforce-frame-pointers=yes" : ""}
  -Clink-arg=-Wl,-z,relro
  -Clink-arg=-Wl,-z,now
  %[0%{?_package_note_status} ? "-Clink-arg=%_package_note_flags" : ""]
  --cap-lints=warn
}

Name:           niri
Version:        %{version}
Release:        1%{?dist}
Summary:        Scrollable-tiling Wayland compositor

SourceLicense:  GPL-3.0-or-later

# (MIT OR Apache-2.0) AND BSD-3-Clause
# (MIT OR Apache-2.0) AND Unicode-3.0
# 0BSD OR MIT OR Apache-2.0
# Apache-2.0
# Apache-2.0 OR BSL-1.0
# Apache-2.0 OR MIT
# Apache-2.0 OR MIT OR Unlicense
# Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT
# BSD-2-Clause
# BSD-2-Clause OR Apache-2.0 OR MIT
# BSD-3-Clause OR MIT OR Apache-2.0
# GPL-3.0-or-later
# ISC
# MIT
# MIT OR Apache-2.0
# MIT OR Apache-2.0 OR LGPL-2.1-or-later
# MIT OR Apache-2.0 OR Zlib
# MIT OR Zlib OR Apache-2.0
# MPL-2.0
# Unicode-3.0
# Unlicense OR MIT
# Zlib OR Apache-2.0 OR MIT
License:        ((MIT OR Apache-2.0) AND BSD-3-Clause) AND ((MIT OR Apache-2.0) AND Unicode-3.0) AND (0BSD OR MIT OR Apache-2.0) AND (Apache-2.0) AND (Apache-2.0 OR BSL-1.0) AND (Apache-2.0 OR MIT) AND (Apache-2.0 OR MIT OR Unlicense) AND (Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT) AND (BSD-2-Clause) AND (BSD-2-Clause OR Apache-2.0 OR MIT) AND (BSD-3-Clause OR MIT OR Apache-2.0) AND (GPL-3.0-or-later) AND (ISC) AND (MIT) AND (MIT OR Apache-2.0) AND (MIT OR Apache-2.0 OR LGPL-2.1-or-later) AND (MIT OR Apache-2.0 OR Zlib) AND (MIT OR Zlib OR Apache-2.0) AND (MPL-2.0) AND (Unicode-3.0) AND (Unlicense OR MIT) AND (Zlib OR Apache-2.0 OR MIT)
# LICENSE.dependencies contains a full license breakdown

URL:            %{url}
%dnl Source:         %{url}/archive/%{commit}.tar.gz
Source:         %{url}/archive/refs/tags/v%{version}.tar.gz
%dnl Source:         niri-%{shortcommit}-vendored-dependencies.tar.xz
%dnl Source:         niri-%{version}-vendored-dependencies.tar.xz
Source:         %{url}/releases/download/v%{version}/niri-%{version}-vendored-dependencies.tar.xz

BuildRequires:  cargo-rpm-macros >= 25
BuildRequires:  pkgconfig(udev)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(xkbcommon)
BuildRequires:  wayland-devel
BuildRequires:  pkgconfig(libinput)
BuildRequires:  pkgconfig(dbus-1)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  pkgconfig(libseat)
BuildRequires:  pkgconfig(libdisplay-info)
BuildRequires:  pipewire-devel
BuildRequires:  pango-devel
BuildRequires:  cairo-gobject-devel
# Needed for pipewire-rs
BuildRequires:  clang

Requires:       mesa-dri-drivers
Requires:       mesa-libEGL

# Portal implementations used by niri
Recommends:     xdg-desktop-portal-gtk
Recommends:     xdg-desktop-portal-gnome
Recommends:     gnome-keyring

# Suggested utilities, bound in the default config
Recommends:     alacritty
Recommends:     fuzzel
Recommends:     swaylock
Recommends:     waybar
# Suggested utilities
Recommends:     swaybg
Recommends:     mako
Recommends:     swayidle

%description
A scrollable-tiling Wayland compositor.

Windows are arranged in columns on an infinite strip going to the right.
Opening a new window never causes existing windows to resize.

%prep
%dnl %autosetup -n %{crate}-%{commit} -p1 -a1
%autosetup -n %{crate}-%{version} -p1 -a1

# We use vendored sources, but they still need a version rather than a git link in Cargo.toml
sed -i 's/^git = "https:\/\/github.com\/Smithay\/smithay.git"$/version = "*"/' Cargo.toml
sed -i 's/git = "https:\/\/gitlab.freedesktop.org\/pipewire\/pipewire-rs.git"/version = "*"/' Cargo.toml

%cargo_prep -v vendor

# Final step in leaving alone our debug settings.
if [ -f .cargo/config.toml ]; then
  sed -i 's/.*please-remove-me$//' .cargo/config.toml
else
  sed -i 's/.*please-remove-me$//' .cargo/config
fi

# Set the build version string.
sed -i 's/\[env\]/[env]\nNIRI_BUILD_VERSION_STRING="%{version} (%{shortcommit})"/' .cargo/config.toml

%build
%cargo_build
%{cargo_license_summary}
%{cargo_license} > LICENSE.dependencies
%{cargo_vendor_manifest}

%install
%cargo_install

install -Dm755 -t %{buildroot}%{_bindir} ./resources/niri-session
install -Dm644 -t %{buildroot}%{_datadir}/wayland-sessions ./resources/niri.desktop
install -Dm644 -t %{buildroot}%{_datadir}/xdg-desktop-portal ./resources/niri-portals.conf
install -Dm644 -t %{buildroot}%{_userunitdir} ./resources/niri.service
install -Dm644 -t %{buildroot}%{_userunitdir} ./resources/niri-shutdown.target

%if %{with check}
%check
%cargo_test -- --workspace --exclude niri-visual-tests
%endif

%files
%license LICENSE
%license LICENSE.dependencies
%license cargo-vendor.txt
%doc README.md
%doc resources/default-config.kdl
%doc wiki
%{_bindir}/niri
%{_bindir}/niri-session
%{_datadir}/wayland-sessions/niri.desktop
%dir %{_datadir}/xdg-desktop-portal
%{_datadir}/xdg-desktop-portal/niri-portals.conf
%{_userunitdir}/niri.service
%{_userunitdir}/niri-shutdown.target

%changelog
%autochangelog
