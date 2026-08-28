/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/


import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import org.kde.latte.components as LatteComponents

Rectangle {
    id: root
    color: "transparent"

    readonly property var theme: Kirigami.Theme
    readonly property var units: Kirigami.Units
    readonly property color safeTextColor: (theme && theme.textColor !== undefined) ? theme.textColor : "white"
    readonly property color safeButtonTextColor: safeTextColor
    readonly property color safeButtonColor: (theme && theme.backgroundColor !== undefined) ? theme.backgroundColor : "white"

    implicitWidth: mainButton.implicitWidth
    implicitHeight: mainButton.implicitHeight

    property bool checked: false
    property bool checkable: false

    readonly property alias comboBox: mainComboBox
    readonly property alias button: mainButton

    property bool buttonEnabled: true
    property bool buttonIsTransparent: false
    property bool buttonIsTriggeringMenu: false
    property string buttonText:""
    property string buttonIconSource:""
    property string buttonToolTip: ""

    property bool comboBoxEnabled: true
    property bool comboBoxBlankSpaceForEmptyIcons: false
    property bool comboBoxForcePressed: false
    property bool comboBoxPopUpAlignRight: true
    property bool comboBoxButtonIsTransparent: false
    property bool comboBoxButtonIsVisible: true
    property int comboBoxMinimumPopUpWidth: 150
    property int comboBoxPopupTextHorizontalAlignment: Text.AlignLeft
    property string comboBoxEnabledRole: ""
    property string comboBoxTextRole: ""
    property string comboBoxIconRole: ""
    property string comboBoxIconToolTipRole: ""
    property string comboBoxIconOnlyWhenHoveredRole: ""
    property string comboBoxIsSeparatorRole: ""

    readonly property bool isButtonIndicatingMenuPopup: buttonIsTriggeringMenu && !comboBoxButtonIsVisible && mainComboBox.popup.visible

    signal iconClicked(int index);

    QQC2.Button {
        id: mainButton
        anchors.left: Qt.application.layoutDirection === Qt.RightToLeft ? undefined : parent.left
        anchors.right: Qt.application.layoutDirection === Qt.RightToLeft ? parent.right : undefined
        LayoutMirroring.enabled: false
        enabled: root.buttonEnabled
        checked: root.checked || (root.buttonIsTriggeringMenu && mainComboBox.popup.visible)
        opacity: root.buttonIsTransparent && !root.isButtonIndicatingMenuPopup ? 0 : 1

        checkable: root.checkable

        width: parent.width
        height: mainComboBox.height

        text: root.checkable ?  " " : root.buttonText
        icon.name: root.buttonIconSource
        palette.button: root.safeButtonColor
        palette.buttonText: root.safeButtonTextColor
        palette.window: root.safeButtonColor
        palette.windowText: root.safeTextColor
        hoverEnabled: true

        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.visible: hovered && root.buttonToolTip !== ""
        QQC2.ToolTip.text: root.buttonToolTip

        onClicked: {
            if (root.buttonIsTriggeringMenu) {
                //! hiding combobox is triggered by default behavior
                mainComboBox.popup.visible = !mainComboBox.popup.visible;
                mainComboBox.down = mainComboBox.popup.visible;
                root.comboBoxForcePressed = mainComboBox.popup.visible;
            }
        }

        onToggled: {
            if (root.checkable) {
                checked = Qt.binding(function() {
                    return root.checked || (root.buttonIsTriggeringMenu && mainComboBox.popup.visible);
                });
            }
        }

        //! WORKAROUND in order to miss one Clicked event from parent button,
        //! when combobox menu is shown and the user clicks the button in order to hide
        //! menu, this is enough in order to be dismissed. Without the workaround
        //! the menu is reshown because the Clicked event is triggered after
        //! the menu became hidden
        MouseArea {
            anchors.fill: parent
            visible: parent.enabled && root.buttonIsTriggeringMenu && mainComboBox.popup.visible
        }
    }

    Connections {
        target: mainComboBox.popup

        function onVisibleChanged() {
            if (root.buttonIsTriggeringMenu) {
                root.comboBoxForcePressed = mainComboBox.popup.visible;
            }
        }
    }

    //overlayed combobox
    LatteComponents.ComboBox {
        id: mainComboBox
        anchors.right: mainButton.right
        anchors.top: parent.top

        width:  units.iconSizes.medium - 2 * units.smallSpacing
        height: parent.height

        enabled: root.comboBoxEnabled
        visible: root.comboBoxButtonIsVisible

        enabledRole: root.comboBoxEnabledRole
        iconRole: root.comboBoxIconRole
        textRole: root.comboBoxTextRole
        iconToolTipRole: root.comboBoxIconToolTipRole
        iconOnlyWhenHoveredRole: root.comboBoxIconOnlyWhenHoveredRole
        isSeparatorRole: root.comboBoxIsSeparatorRole
        buttonIsTransparent: root.comboBoxButtonIsTransparent

        blankSpaceForEmptyIcons: root.comboBoxBlankSpaceForEmptyIcons
        forcePressed: root.comboBoxForcePressed
        popUpAlignRight: root.comboBoxPopUpAlignRight
        popUpRelativeX: Qt.application.layoutDirection === Qt.RightToLeft ?
                            (root.comboBoxPopUpAlignRight ? root.width - width : 0) :
                            (root.comboBoxPopUpAlignRight ? width : -(root.width - width))
        popUpTextHorizontalAlignment: root.comboBoxPopupTextHorizontalAlignment

        hideDisplayText: true
        hideSelectedItemIcon: true

        minimumPopUpWidth: Math.max(root.comboBoxMinimumPopUpWidth, root.width)

        function onIconClicked(index) {
            root.iconClicked(index);
        }
    }

    PlasmaComponents3.Label{
        width: labelMetrics.exceeds ? parent.width-mainComboBox.width :  parent.width
        height: parent.height
        text: root.buttonText
        font: mainButton.font
        color: root.buttonIsTransparent ? root.safeTextColor : root.safeButtonTextColor
        visible: root.checkable || (mainButton.opacity === 0)

        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    PlasmaComponents3.Label{
        id: labelMetrics
        text: root.buttonText
        opacity: 0
        elide: Text.ElideNone
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        readonly property bool exceeds: width>(mainButton.width-2*mainComboBox.width)
    }
}
