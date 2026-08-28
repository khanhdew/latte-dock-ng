/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.latte.core as LatteCore

Grid {
    id: appletsContainer

    // Keep the layout single-row/single-column while giving Grid enough capacity
    // during transient edge/form-factor changes before children are fully settled.
    columns: 99999
    columnSpacing: 0
    flow: isHorizontal ? Grid.LeftToRight : Grid.TopToBottom
    rows: 99999
    rowSpacing: 0

    opacity: 1

    readonly property real length : root.isHorizontal ? width - ignoredLength : height - ignoredLength
    property real ignoredLength: 0

    property int alignment: LatteCore.types.BottomEdgeCenterAlign
    property int beginIndex: 0
    property int offset: 0

    //////////////////////////BEGIN states
    //user set Panel Positions
    // 0-Center, 1-Left, 2-Right, 3-Top, 4-Bottom
    states: [
        ///Left Edge
        State {
            name: "leftCenter"
            when: appletsContainer.alignment === LatteCore.types.LeftEdgeCenterAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:parent.verticalCenter}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignLeft; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: appletsContainer.offset;
            }
        },
        State {
            name: "leftTop"
            when: appletsContainer.alignment === LatteCore.types.LeftEdgeTopAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignLeft; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: appletsContainer.offset;    appletsContainer.anchors.bottomMargin: appletsContainer.lastMargin;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "leftBottom"
            when: appletsContainer.alignment === LatteCore.types.LeftEdgeBottomAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:parent.bottom; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignLeft; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: appletsContainer.lastMargin;    appletsContainer.anchors.bottomMargin: appletsContainer.offset;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        ///Right Edge
        State {
            name: "rightCenter"
            when: appletsContainer.alignment === LatteCore.types.RightEdgeCenterAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:parent.verticalCenter}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignRight; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: appletsContainer.offset;
            }
        },
        State {
            name: "rightTop"
            when: appletsContainer.alignment === LatteCore.types.RightEdgeTopAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignRight; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: appletsContainer.offset;    appletsContainer.anchors.bottomMargin: appletsContainer.lastMargin;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "rightBottom"
            when: appletsContainer.alignment === LatteCore.types.RightEdgeBottomAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:parent.bottom; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignRight; appletsContainer.verticalItemAlignment: Grid.AlignVCenter;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: appletsContainer.lastMargin;    appletsContainer.anchors.bottomMargin: appletsContainer.offset;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        ///Bottom Edge
        State {
            name: "bottomCenter"
            when: appletsContainer.alignment === LatteCore.types.BottomEdgeCenterAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:parent.bottom; left:undefined; right:undefined; horizontalCenter:parent.horizontalCenter; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignBottom;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: appletsContainer.offset; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "bottomLeft"
            when: appletsContainer.alignment === LatteCore.types.BottomEdgeLeftAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:parent.bottom; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignBottom;
                appletsContainer.anchors.leftMargin: appletsContainer.offset;    appletsContainer.anchors.rightMargin: appletsContainer.lastMargin;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "bottomRight"
            when: appletsContainer.alignment === LatteCore.types.BottomEdgeRightAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:undefined; bottom:parent.bottom; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignBottom;
                appletsContainer.anchors.leftMargin: appletsContainer.lastMargin;    appletsContainer.anchors.rightMargin: appletsContainer.offset;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        ///Top Edge
        State {
            name: "topCenter"
            when: appletsContainer.alignment === LatteCore.types.TopEdgeCenterAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:parent.top; bottom:undefined; left:undefined; right:undefined; horizontalCenter:parent.horizontalCenter; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignTop;
                appletsContainer.anchors.leftMargin: 0;    appletsContainer.anchors.rightMargin: 0;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: appletsContainer.offset; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "topLeft"
            when: appletsContainer.alignment === LatteCore.types.TopEdgeLeftAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:parent.top; bottom:undefined; left:parent.left; right:undefined; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignTop;
                appletsContainer.anchors.leftMargin: appletsContainer.offset;    appletsContainer.anchors.rightMargin: appletsContainer.lastMargin;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "topRight"
            when: appletsContainer.alignment === LatteCore.types.TopEdgeRightAlign

            AnchorChanges {
                target: appletsContainer
                anchors{ top:parent.top; bottom:undefined; left:undefined; right:parent.right; horizontalCenter:undefined; verticalCenter:undefined}
            }
            PropertyChanges{
                appletsContainer.horizontalItemAlignment: Grid.AlignHCenter; appletsContainer.verticalItemAlignment: Grid.AlignTop;
                appletsContainer.anchors.leftMargin: appletsContainer.lastMargin;    appletsContainer.anchors.rightMargin: appletsContainer.offset;     appletsContainer.anchors.topMargin: 0;    appletsContainer.anchors.bottomMargin: 0;
                appletsContainer.anchors.horizontalCenterOffset: 0; appletsContainer.anchors.verticalCenterOffset: 0;
            }
        }
    ]
    ////////////////END states
}
