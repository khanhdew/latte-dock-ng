/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.core as PlasmaCore

import "controls" as SettingsControls

Item {
    id: headerSettings
    required property var root
    required property var latteView
    required property var plasmoid
    required property var settingsRoot
    readonly property var _root: headerSettings.root
    readonly property var _latteView: headerSettings.latteView
    readonly property var _plasmoid: headerSettings.plasmoid
    readonly property var _settingsRoot: headerSettings.settingsRoot

    width: _plasmoid && parent ? (_plasmoid.formFactor === PlasmaCore.Types.Horizontal ? parent.width : parent.height) : 0
    height: thickness

    readonly property bool containsMouse: stickOnBottomBtn.containsMouse || stickOnTopBtn.containsMouse
    readonly property int thickness: stickOnTopBtn.implicitHeight

    readonly property int headMargin: _settingsRoot ? _settingsRoot.spacing * 2 : 0

    rotation: {
        if (!_plasmoid || _plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return  0;
        }

        if (_plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return 90;
        } else if (_plasmoid.location === PlasmaCore.Types.RightEdge) {
            return -90;
        }
    }

    x: {
        if (!_plasmoid || !_latteView || !_plasmoid.formFactor || !parent) {
            return 0;
        }

        if (_plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return 0;
        }

        if (_plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return _latteView.maxNormalThickness + headMargin * 2 - width/2 + height/2;
        } else if (_plasmoid.location === PlasmaCore.Types.RightEdge) {
            return headMargin - width/2 + height/2;
        }
    }

    y: {
        if (!_plasmoid || !parent) {
            return 0;
        }

        if (_plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return width/2 - height/2;
        }

        if (_plasmoid.location === PlasmaCore.Types.BottomEdge) {
            return headMargin;
        } else if (_plasmoid.location === PlasmaCore.Types.TopEdge) {
            return parent.height - stickOnTopBtn.height - headMargin;
        }
    }

    SettingsControls.Button{
        id: stickOnTopBtn
        latteView: headerSettings._latteView
        settingsRoot: headerSettings._settingsRoot
        visible: headerSettings._root ? headerSettings._root.isVertical : false

        text: i18n("Stick On Top");
        tooltip: i18n("Stick maximum available space at top screen edge and ignore any top docks")
        checked: headerSettings._plasmoid && headerSettings._plasmoid.configuration
                 ? headerSettings._plasmoid.configuration.isStickedOnTopEdge : false
        iconPositionReversed: !!(headerSettings._plasmoid
                                 && headerSettings._plasmoid.location === PlasmaCore.Types.RightEdge)

        icon: SettingsControls.StickIcon{}

        onPressedChanged: {
            if (pressed && headerSettings._plasmoid && headerSettings._plasmoid.configuration) {
                headerSettings._plasmoid.configuration.isStickedOnTopEdge = !headerSettings._plasmoid.configuration.isStickedOnTopEdge;
            }
        }

        states: [
            State {
                name: "generalEdge"
                when: !!(headerSettings._plasmoid
                         && headerSettings._plasmoid.location !== PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnTopBtn
                    anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
                }
            },
            State {
                name: "rightEdge"
                when: !!(headerSettings._plasmoid
                         && headerSettings._plasmoid.location === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnTopBtn
                    anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
                }
            }
        ]
    }


    SettingsControls.Button{
        id: stickOnBottomBtn
        latteView: headerSettings._latteView
        settingsRoot: headerSettings._settingsRoot
        visible: headerSettings._root ? headerSettings._root.isVertical : false

        text: i18n("Stick On Bottom");
        tooltip: i18n("Stick maximum available space at bottom screen edge and ignore any bottom docks")
        checked: headerSettings._plasmoid && headerSettings._plasmoid.configuration
                 ? headerSettings._plasmoid.configuration.isStickedOnBottomEdge : false
        iconPositionReversed: !!(headerSettings._plasmoid
                                 && headerSettings._plasmoid.location !== PlasmaCore.Types.RightEdge)

        icon: SettingsControls.StickIcon{}

        onPressedChanged: {
            if (pressed && headerSettings._plasmoid && headerSettings._plasmoid.configuration) {
                headerSettings._plasmoid.configuration.isStickedOnBottomEdge = !headerSettings._plasmoid.configuration.isStickedOnBottomEdge;
            }
        }

        states: [
            State {
                name: "generalEdge"
                when: !!(headerSettings._plasmoid
                         && headerSettings._plasmoid.location !== PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnBottomBtn
                    anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
                }
            },
            State {
                name: "rightEdge"
                when: !!(headerSettings._plasmoid
                         && headerSettings._plasmoid.location === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnBottomBtn
                    anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
                }
            }
        ]
    }
}
