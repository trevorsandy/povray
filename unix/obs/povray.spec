#
# spec file for package lpub3d
#
# Copyright © 2017 Trevor SANDY
# Using RPM Spec file examples from SUSE LINUX GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# please send bugfixes or comments to Trevor SANDY <trevor.sandy@gmail.com>
#

%define maj_version 3.8
%define min_version 0.0
Name:           povray
Version:        %{maj_version}.%{min_version}
Release:        0
Summary:        Ray Tracer
License:        AGPL-3.0 and CC-BY-SA-3.0
Group:          Productivity/Graphics/Visualization/Raytracers
Url:            http://www.povray.org
Source:         https://github.com/trevorsandy/povray/archive/lpub3d/raytracer-cui.tar.gz
BuildRequires:  autoconf
BuildRequires:  automake
%if 0%{?suse_version} > 1325
BuildRequires:  libboost_system-devel
BuildRequires:  libboost_thread-devel
%else
BuildRequires:  boost-devel
%endif
BuildRequires:  dos2unix
BuildRequires:  fdupes
BuildRequires:  gcc-c++
BuildRequires:  libjpeg-devel
BuildRequires:  libpng-devel
BuildRequires:  libtiff-devel
%if 0%{?suse_version}
BuildRequires:  xorg-x11-libX11-devel
BuildRequires:  xorg-x11-libXpm-devel
%else
BuildRequires:  libXpm-devel
%endif
BuildRequires:  pkgconfig(OpenEXR)
BuildRequires:  pkgconfig(sdl2)
BuildRequires:  pkgconfig(zlib)
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
LPub3D-Trace is a modified, unofficial distribution of
Persistence of Vision Ray Tracer ('POV-Ray') version 3.8 developed and
maintained by Trevor SANDY for LPub3D. The POV-Ray Team is not responsible
for supporting this version. LPub3D-Trace Ray tracer creates three-dimensional,
photo-realistic images using a rendering technique called ray tracing.
It reads in a text file containing information describing the objects
and lighting in a scene and generates an image of that scene from the
view point of a camera also described in the text file. Ray tracing is
not a fast process by any means, (the generation of a complex image can
take several hours) but it produces very high quality images with
realistic reflections, shading, perspective, and other effects.

%prep
%setup -q

# remove inline copies of shared libraries
rm -rf libraries

# fix wrong newline encoding
dos2unix -k unix/scripts/*.sh

%build
( cd unix && chmod +x prebuild3rdparty.sh && ./prebuild3rdparty.sh )
CXXFLAGS="%{optflags} -fno-strict-aliasing -Wno-multichar" CFLAGS="$CXXFLAGS" \
    %configure COMPILED_BY="Trevor SANDY <trevor.sandy@gmail.com>" \
    --disable-strip \
    --disable-optimiz \
    --with-libsdl2 \
    --enable-watch-cursor

# fix up paths
sed -i -e 's,^DEFAULT_DIR=.*,DEFAULT_DIR=/usr,' scripts/*
sed -i -e 's,^SYSCONFDIR=.*,SYSCONFDIR=/etc,' scripts/*

make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} \
     povdocdir=/deleteme \
     install

# this only contains the AUTHORS and changelog files, not the actual
# documentation
rm -rf %{buildroot}/deleteme

# fix wrong permissions
chmod 755 %{buildroot}%{_datadir}/povray-%{maj_version}/scenes/camera/mesh_camera/bake.sh

%fdupes %{buildroot}/%{_datadir}

%files
%defattr(-,root,root)
%doc AUTHORS LICENSE README.md changes.txt revision.txt
%dir %{_sysconfdir}/%{name}
%dir %{_sysconfdir}/%{name}/%{maj_version}
%config(noreplace) %{_sysconfdir}/%{name}/%{maj_version}/%{name}.*
%{_bindir}/povray
%{_datadir}/povray-%{maj_version}
%{_mandir}/man1/povray.1*

%changelog
