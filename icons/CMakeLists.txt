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

# The plasmoid icon name contains dots, which ecm_install_icons cannot
# parse, so install it with a plain rule into the scalable app context.
install(FILES org.kde.latte.plasmoid.svg
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)
