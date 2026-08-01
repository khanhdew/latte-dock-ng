# Refresh desktop and icon caches when latte-dock-ng is installed or removed,
# so new icons and .desktop entries appear without a session restart.
# This file is embedded verbatim into the RPM %post/%postun sections by
# CPack, so it must not contain a shebang line.
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q 2>/dev/null || true
fi
