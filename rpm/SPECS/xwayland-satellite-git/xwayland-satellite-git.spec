%global commit0 ec9ff64c1e0cbec42710b580b7c0f759b1694e72
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 0

Name:           xwayland-satellite-git
Version:        0.5.1%{?bumpver:^%{bumpver}.git%{shortcommit0}}
Release:        %autorelease
Summary:        xwayland-satellite

License:        MIT
URL:            https://github.com/Supreeeme/xwayland-satellite
Source0:        %{url}/archive/%{commit0}/%{name}-%{shortcommit0}.tar.gz

BuildRequires:  cargo-rpm-macros
BuildRequires:  clang
BuildRequires:  pkgconfig(xcb)
BuildRequires:  pkgconfig(xcb-cursor)
BuildRequires:  xorg-x11-server-Xwayland

Obsoletes:      xwayland-satellite < %{version}-%{release}

%description
xwayland-satellite grants rootless Xwayland integration to any
Wayland compositor implementing xdg_wm_base and viewporter.

%prep
%autosetup -n xwayland-satellite-%{commit0}
cargo vendor
%cargo_prep -v vendor

%build
%cargo_build

%install
install -Dm755 target/release/xwayland-satellite -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/xwayland-satellite

%changelog
%autochangelog
