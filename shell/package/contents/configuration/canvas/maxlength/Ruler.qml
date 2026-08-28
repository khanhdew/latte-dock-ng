/*
    SPDX-FileCopyrightText: 2018 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import org.kde.latte.core as LatteCore

Item{
    id: rulerItem
    required property var root
    required property var plasmoid
    required property var settingsRoot
    readonly property var rulerItemReference: rulerItem

    Kirigami.Theme.inherit: true
    readonly property var theme: Kirigami.Theme

    width: root.isHorizontal ? userMaxLength : thickness
    height: root.isVertical ? userMaxLength : thickness

    property int rulerAnimationTime: root.animationSpeed
    property int thicknessMargin: 0

    readonly property bool containsMouse: rulerMouseArea.containsMouse
    readonly property int thickness: theme.defaultFont.pixelSize

    readonly property string tooltip: i18nc("maximum length tooltip, %1 is maximum length percentage","You can use mouse wheel to change maximum length of %1%",plasmoid.configuration.maxLength)

    readonly property int userMaxLength: {
        if (root.isHorizontal) {
            return root.width * (plasmoid.configuration.maxLength/100);
        } else {
            return root.height * (plasmoid.configuration.maxLength/100);
        }
    }

    x: {
        if (root.isHorizontal) {
            return xL;
        } else {
            if (plasmoid.location === PlasmaCore.Types.LeftEdge){
                return settingsRoot.width - thickness - thicknessMargin;
            } else if (plasmoid.location === PlasmaCore.Types.RightEdge){
                return thicknessMargin;
            }
        }
    }

    y: {
        if (root.isVertical) {
            return yL;
        } else {
            if (plasmoid.location === PlasmaCore.Types.BottomEdge){
                return thicknessMargin;
            } else if (plasmoid.location === PlasmaCore.Types.TopEdge){
                return settingsRoot.height - thickness - thicknessMargin;
            }
        }

    }

    property int length: userMaxLength

    property int thickMargin: 3
    property int xL: 0
    property int yL: 0

    Binding{
        target: rulerItem
        property: "xL"
        value: {
            if (rulerItem.root.isHorizontal) {
                if (rulerItem.plasmoid.configuration.alignment === LatteCore.types.Justify) {
                    return rulerItem.root.width/2 - rulerItem.length/2 + rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Left) {
                    return rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Center) {
                    return rulerItem.root.width/2 - rulerItem.length/2 + rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Right) {
                    return rulerItem.root.width - rulerItem.length - rulerItem.root.offset;
                }
            } else {
                return ;
            }
        }
    }

    Binding{
        target: rulerItem
        property: "yL"
        value: {
            if (rulerItem.root.isVertical) {
                if (rulerItem.plasmoid.configuration.alignment === LatteCore.types.Justify) {
                    return rulerItem.root.height/2 - rulerItem.length/2 + rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Top) {
                    return rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Center) {
                    return rulerItem.root.height/2 - rulerItem.length/2 + rulerItem.root.offset;
                } else if (rulerItem.root.panelAlignment === LatteCore.types.Bottom) {
                    return rulerItem.root.height - rulerItem.length - rulerItem.root.offset;
                }
            } else {
                return;
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            id: horizontalAnimation
            duration: rulerItem.rulerAnimationTime
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            id: verticalAnimation
            duration: rulerItem.rulerAnimationTime
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        enabled: rulerItem.root.isHorizontal && !horizontalAnimation.running
        NumberAnimation {
            duration: rulerItem.rulerAnimationTime
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: rulerItem.root.isVertical && !verticalAnimation.running
        NumberAnimation {
            duration: rulerItem.rulerAnimationTime
            easing.type: Easing.OutCubic
        }
    }

    Flow{
        id: rulerGrid
        width: rulerItem.root.isHorizontal ? rulerItem.length : undefined
        height: rulerItem.root.isVertical ? rulerItem.length : undefined

        spacing: 2

        flow: rulerItem.root.isHorizontal ? Flow.LeftToRight : Flow.TopToBottom

        x: {
            if (rulerItem.plasmoid.location === PlasmaCore.Types.LeftEdge) {
                return -rulerItem.thickMargin;
            } else if (rulerItem.plasmoid.location === PlasmaCore.Types.RightEdge) {
                return rulerItem.thickMargin;
            } else {
                return 0;
            }
        }

        y: {
            if (rulerItem.plasmoid.location === PlasmaCore.Types.BottomEdge) {
                return rulerItem.thickMargin;
            } else if (rulerItem.plasmoid.location === PlasmaCore.Types.TopEdge) {
                return -rulerItem.thickMargin;
            } else {
                return 0;
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: rulerItem.rulerAnimationTime
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: rulerItem.rulerAnimationTime
                easing.type: Easing.OutCubic
            }
        }

        property int freeSpace: {
            if (rulerItem.root.isHorizontal) {
                return rulerItem.width - rulerGrid.spacing - 1 //((rulerGrid.children.length-2) * rulerGrid.spacing)
                        - (startLine.width + startArrow.width + labelItem.width + endArrow.width + endArrow.width);
            } else {
                return rulerItem.height - rulerGrid.spacing - 1 //((rulerGrid.children.length-2) * rulerGrid.spacing)
                        - (startLine.height + startArrow.height + labelItem.height + endArrow.height + endArrow.height);
            }
        }

        Rectangle{
            id: startLine
            width: rulerItem.root.isHorizontal ? 2 : rulerItem.theme.defaultFont.pixelSize
            height: rulerItem.root.isVertical ? 2 : rulerItem.theme.defaultFont.pixelSize

            color: rulerItem.settingsRoot.textColor
        }

        Item{
            id: startArrow
            width: rulerItem.root.isHorizontal ? 0.6 * rulerItem.theme.defaultFont.pixelSize : rulerItem.theme.defaultFont.pixelSize
            height: rulerItem.root.isVertical ? 0.6 * rulerItem.theme.defaultFont.pixelSize : rulerItem.theme.defaultFont.pixelSize

            clip:true

            Rectangle{
                anchors.verticalCenter: rulerItem.root.isHorizontal ? parent.verticalCenter : parent.bottom
                anchors.horizontalCenter: rulerItem.root.isHorizontal ? parent.right : parent.horizontalCenter
                width: 0.75*rulerItem.theme.defaultFont.pixelSize
                height: width
                rotation: 45

                color: rulerItem.settingsRoot.textColor
            }
        }

        Item{
            id: startSpacer
            width: rulerItem.root.isHorizontal ? rulerGrid.freeSpace / 2 : rulerItem.theme.defaultFont.pixelSize
            height: rulerItem.root.isVertical ? rulerGrid.freeSpace / 2 : rulerItem.theme.defaultFont.pixelSize

            Rectangle{
                height: rulerItem.root.isHorizontal ? 2 : parent.height
                width: rulerItem.root.isVertical ? 2 : parent.width

                anchors.centerIn: parent

                color: rulerItem.settingsRoot.textColor
            }
        }

        Item {
            id: labelItem
            width: rulerItem.root.isHorizontal ? labelMetricsRec.width : labelMetricsRec.height / 2
            height: rulerItem.root.isVertical ? labelMetricsRec.width : labelMetricsRec.height / 2

            PlasmaComponents.Label{
                id: maxLengthLbl

                anchors.centerIn: parent

                text: i18n("Maximum Length")
                color: rulerItem.settingsRoot.textColor

                transformOrigin: Item.Center

                rotation: {
                    if (rulerItem.root.isHorizontal) {
                        return 0;
                    } else if (rulerItem.plasmoid.location === PlasmaCore.Types.LeftEdge){
                        return 90;
                    } else if (rulerItem.plasmoid.location === PlasmaCore.Types.RightEdge){
                        return -90;
                    }
                }

                Rectangle {
                    id: labelMetricsRec
                    anchors.fill: parent
                    visible: false
                }
            }
        }

        Item{
            id: endSpacer
            width: startSpacer.width
            height: startSpacer.height

            Rectangle{
                height: rulerItem.root.isHorizontal ? 2 : parent.height
                width: rulerItem.root.isVertical ? 2 : parent.width

                anchors.centerIn: parent

                color: rulerItem.settingsRoot.textColor
            }
        }

        Item{
            id: endArrow
            width: rulerItem.root.isHorizontal ? 0.6 * rulerItem.theme.defaultFont.pixelSize : rulerItem.theme.defaultFont.pixelSize
            height: rulerItem.root.isVertical ? 0.6 * rulerItem.theme.defaultFont.pixelSize : rulerItem.theme.defaultFont.pixelSize
            clip:true

            Rectangle{
                anchors.verticalCenter: rulerItem.root.isHorizontal ? parent.verticalCenter : parent.top
                anchors.horizontalCenter: rulerItem.root.isHorizontal ? parent.left : parent.horizontalCenter
                width: 0.75*rulerItem.theme.defaultFont.pixelSize
                height: width
                rotation: 45

                color: rulerItem.settingsRoot.textColor
            }
        }

        Rectangle{
            id: endLine
            width: rulerItem.root.isHorizontal ? 2 : rulerItem.theme.defaultFont.pixelSize
            height: rulerItem.root.isVertical ? 2 : rulerItem.theme.defaultFont.pixelSize

            color: rulerItem.settingsRoot.textColor
        }
    } // end of grid

    RulerMouseArea {
        id: rulerMouseArea
        root: rulerItem.root
        plasmoid: rulerItem.plasmoid
        rulerItem: rulerItem.rulerItemReference
        anchors.fill: parent
    }

    PlasmaComponents.Button {
        anchors.fill: parent
        opacity: 0
        Kirigami.Theme.inherit: true
        hoverEnabled: true

        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.visible: hovered && rulerItem.tooltip !== ""
        QQC2.ToolTip.text: rulerItem.tooltip
    }
}
