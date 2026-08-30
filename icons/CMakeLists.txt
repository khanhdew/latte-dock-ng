include(ECMInstallIcons)

ecm_install_icons(ICONS
    16-apps-latte-dock.svg
    22-apps-latte-dock.svg
    24-apps-latte-dock.svg
    32-apps-latte-dock.svg
    48-apps-latte-dock.svg
    sc-apps-latte-dock.svg
THEME hicolor
DESTINATION ${KDE_INSTALL_ICONDIR})

# ECM's icon helper is intended for SVG/SVGZ assets and warns for PNG files.
# Install the raster fallbacks explicitly, preserving the legacy icon name.
foreach(_latte_icon_size 16 22 24 32 48)
    install(FILES ${_latte_icon_size}-apps-latte-dock.png
            DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/${_latte_icon_size}x${_latte_icon_size}/apps
            RENAME latte-dock.png)
endforeach()
install(FILES sc-apps-latte-dock.png
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps
        RENAME latte-dock.png)

# Use a new icon name for the current application artwork.  Keeping the
# legacy latte-dock files above preserves compatibility with existing themes,
# while the versioned name prevents KDE's icon cache from returning a stale
# icon after an upgrade.
foreach(_latte_icon_size 16 22 24 32 48)
    install(FILES ${_latte_icon_size}-apps-latte-dock.svg
            DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/${_latte_icon_size}x${_latte_icon_size}/apps
            RENAME latte-dock-ng.svg)
    install(FILES ${_latte_icon_size}-apps-latte-dock.png
            DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/${_latte_icon_size}x${_latte_icon_size}/apps
            RENAME latte-dock-ng.png)
endforeach()
install(FILES sc-apps-latte-dock.svg
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps
        RENAME latte-dock-ng.svg)
install(FILES sc-apps-latte-dock.png
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps
        RENAME latte-dock-ng.png)

# The plasmoid icon name contains dots, which ecm_install_icons cannot
# parse, so install it with a plain rule into the scalable app context.
install(FILES org.kde.latte.plasmoid.svg
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)
