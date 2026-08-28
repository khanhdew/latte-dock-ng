/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.core as PlasmaCore
import QtQuick.Effects

Item{
    id: shadowRoot

    property int shadowDirection: PlasmaCore.Types.BottomEdge
    property int shadowSize: 7
    property real shadowOpacity: 1
    property color shadowColor: "#040404"

    readonly property bool isHorizontal : (shadowDirection !== PlasmaCore.Types.LeftEdge) && (shadowDirection !== PlasmaCore.Types.RightEdge)

    // These implicit sizes intentionally define the shadow component's content size.
    // qmllint disable property-override
    readonly property int implicitWidth: shadow.width
    readonly property int implicitHeight: shadow.height
    // qmllint enable property-override

    Item{
        id: shadow
        width: isHorizontal ? shadowRoot.width + 2*shadowSize : shadowSize
        height: isHorizontal ? shadowSize: shadowRoot.height + 2*shadowSize
        opacity: shadowOpacity

        clip: true

        Rectangle{
            id: editShadow
            width: shadowRoot.width
            height: shadowRoot.height
            color: "white"

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: shadowRoot.shadowColor
                shadowBlur: Math.min(shadowSize / 64.0, 1.0)
            }
        }

        states: [
            ///topShadow
            State {
                name: "topShadow"
                when: (shadowDirection === PlasmaCore.Types.BottomEdge)

                AnchorChanges {
                    target: editShadow
                    anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined}
                }
                PropertyChanges{
                    editShadow.anchors.leftMargin: 0; editShadow.anchors.rightMargin:0; editShadow.anchors.topMargin:shadowSize; editShadow.anchors.bottomMargin:0
                }
            },
            ///bottomShadow
            State {
                name: "bottomShadow"
                when: (shadowDirection === PlasmaCore.Types.TopEdge)

                AnchorChanges {
                    target: editShadow
                    anchors{ top:undefined; bottom:parent.bottom; left:parent.left; right:undefined}
                }
                PropertyChanges{
                    editShadow.anchors.leftMargin: 0; editShadow.anchors.rightMargin:0; editShadow.anchors.topMargin:0; editShadow.anchors.bottomMargin:shadowSize
                }
            },
            ///leftShadow
            State {
                name: "leftShadow"
                when: (shadowDirection === PlasmaCore.Types.RightEdge)

                AnchorChanges {
                    target: editShadow
                    anchors{ top:parent.top; bottom: undefined; left:parent.left; right:undefined}
                }
                PropertyChanges{
                    editShadow.anchors.leftMargin: shadowSize; editShadow.anchors.rightMargin:0; editShadow.anchors.topMargin:0; editShadow.anchors.bottomMargin:0
                }
            },
            ///rightShadow
            State {
                name: "rightShadow"
                when: (shadowDirection === PlasmaCore.Types.LeftEdge)

                AnchorChanges {
                    target: editShadow
                    anchors{top:parent.top; bottom:undefined; left:undefined; right:parent.right}
                }
                PropertyChanges{
                    editShadow.anchors.leftMargin: 0; editShadow.anchors.rightMargin:shadowSize; editShadow.anchors.topMargin:0; editShadow.anchors.bottomMargin:0
                }
            }
        ]
    }
}
