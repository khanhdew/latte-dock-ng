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
    required property var ruler
    required property var settingsRoot
    width: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? parent.width : parent.height
    height: thickness

    readonly property bool containsMouse: stickOnBottomBtn.containsMouse || stickOnTopBtn.containsMouse
    readonly property int thickness: stickOnTopBtn.implicitHeight

    readonly property int headMargin: headerSettings.settingsRoot.spacing * 2

    rotation: {
        if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return  0;
        }

        if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return 90;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            return -90;
        }
    }

    x: {
        if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return 0;
        }

        if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return latteView.maxNormalThickness + ruler.thickness + headMargin * 2 - width/2 + height/2;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            return headMargin - width/2 + height/2;
        }
    }

    y: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return width/2 - height/2;
        }

        if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            return headMargin;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            return parent.height - stickOnTopBtn.height - headMargin;
        }
    }

    SettingsControls.Button{
        id: stickOnTopBtn
        latteView: headerSettings.latteView
        settingsRoot: headerSettings.parent
        visible: headerSettings.root.isVertical

        text: i18n("Stick On Top");
        tooltip: i18n("Stick maximum available space at top screen edge and ignore any top docks")
        checked: headerSettings.plasmoid.configuration.isStickedOnTopEdge
        iconPositionReversed: (headerSettings.plasmoid.location === PlasmaCore.Types.RightEdge)

        icon: SettingsControls.StickIcon{}

        onPressedChanged: {
            if (pressed) {
                headerSettings.plasmoid.configuration.isStickedOnTopEdge = !headerSettings.plasmoid.configuration.isStickedOnTopEdge;
            }
        }

        states: [
            State {
                name: "generalEdge"
                when: (headerSettings.plasmoid.location !== PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnTopBtn
                    anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
                }
            },
            State {
                name: "rightEdge"
                when: (headerSettings.plasmoid.location === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnTopBtn
                    anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
                }
            }
        ]
    }


    SettingsControls.Button{
        id: stickOnBottomBtn
        latteView: headerSettings.latteView
        settingsRoot: headerSettings.parent
        visible: headerSettings.root.isVertical

        text: i18n("Stick On Bottom");
        tooltip: i18n("Stick maximum available space at bottom screen edge and ignore any bottom docks")
        checked: headerSettings.plasmoid.configuration.isStickedOnBottomEdge
        iconPositionReversed: (headerSettings.plasmoid.location !== PlasmaCore.Types.RightEdge)

        icon: SettingsControls.StickIcon{}

        onPressedChanged: {
            if (pressed) {
                headerSettings.plasmoid.configuration.isStickedOnBottomEdge = !headerSettings.plasmoid.configuration.isStickedOnBottomEdge;
            }
        }

        states: [
            State {
                name: "generalEdge"
                when: (headerSettings.plasmoid.location !== PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnBottomBtn
                    anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
                }
            },
            State {
                name: "rightEdge"
                when: (headerSettings.plasmoid.location === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: stickOnBottomBtn
                    anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
                }
            }
        ]
    }
}
