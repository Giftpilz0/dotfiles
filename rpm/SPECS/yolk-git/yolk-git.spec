%global commit0 4a73edd962cdff0e88191d868ac6b6b96ba0ae54
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 0

Name:           yolk-git
Version:        0.3.4%{?bumpver:^%{bumpver}.git%{shortcommit0}}
Release:        %autorelease
Summary:        Yolk

License:        MIT
URL:            https://github.com/elkowar/yolk
Source0:        %{url}/archive/%{commit0}/%{name}-%{shortcommit0}.tar.gz

BuildRequires:  cargo-rpm-macros

Obsoletes:      yolk < %{version}-%{release}

%description
Yolk is a cross platform dotfile management tool with a unique spin on templating,
sitting somewhere in between GNU Stow and chezmoi.

%prep
%autosetup -n yolk-%{commit0}
cargo vendor
%cargo_prep -v vendor

%build
%cargo_build

%install
install -Dm755 target/release/yolk -t %{buildroot}%{_bindir}

%files
%license LICENSE.md
%doc docs/ README.md
%{_bindir}/yolk

%changelog
%autochangelog
