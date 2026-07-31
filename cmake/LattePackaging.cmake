# SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

# Generates RPM (Fedora/openSUSE) or DEB (Debian/Ubuntu) packages.
# Usage: cmake --build . && cpack -G RPM   (or -G DEB)
set(CPACK_PACKAGE_NAME "latte-dock-ng")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_VENDOR "${AUTHOR}")
set(CPACK_PACKAGE_CONTACT "${EMAIL}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Latte Dock NG - Plasma 6 desktop dock")
set(CPACK_PACKAGE_HOMEPAGE_URL "${WEBSITE}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSES/GPL-3.0.txt")

# RPM
set(CPACK_RPM_PACKAGE_NAME "latte-dock-ng")
set(CPACK_RPM_PACKAGE_RELEASE "1")
set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
set(CPACK_RPM_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}.${CPACK_RPM_PACKAGE_ARCHITECTURE}.rpm")
set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0-or-later")
set(CPACK_RPM_PACKAGE_URL "${WEBSITE}")
set(CPACK_RPM_PACKAGE_AUTOREQ ON)
set(CPACK_RPM_PACKAGE_AUTOPROV ON)
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
    /usr/share/applications
    /usr/share/icons
    /usr/share/latte
    /usr/share/plasma
)
# QML modules not captured by .so auto-detection:
# - kirigami: loaded via QML import, no direct .so link from latte
# - kcmutils: loaded by the configuration shell QML
# - knewstuff: QML plugin files needed at runtime
set(CPACK_RPM_PACKAGE_REQUIRES "kf6-kirigami, kf6-kcmutils, kf6-knewstuff")

# DEB
set(CPACK_DEBIAN_PACKAGE_NAME "latte-dock-ng")
set(CPACK_DEBIAN_PACKAGE_RELEASE "1")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_FILE_NAME "${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}.deb")
set(CPACK_DEBIAN_PACKAGE_SECTION "kde")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "${WEBSITE}")
set(CPACK_DEBIAN_PACKAGE_SHLIBS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
# Versioned runtime library dependencies via dpkg-shlibdeps. The lower
# bound is whatever the build machine ships, so the deb must be built on
# the oldest supported distro (Debian 13 trixie) for the package to stay
# installable on Debian stable/testing/sid and Ubuntu 26.04+.
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# QML modules not captured by .so auto-detection
set(CPACK_DEBIAN_PACKAGE_DEPENDS "qml6-module-org-kde-kirigami, qml6-module-org-kde-kcmutils, qml6-module-org-kde-newstuff")

include(CPack)
