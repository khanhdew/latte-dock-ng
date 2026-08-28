/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.latte.core as LatteCore
import org.kde.latte.components as LatteComponents

LatteComponents.ComboBoxButton{
    id: custom
    required property var latteView
    checkable: true

    buttonText: modes[currentModeIndex].name
    buttonToolTip: modes[currentModeIndex].tooltip

    comboBoxTextRole: "name"
    comboBoxMinimumPopUpWidth: width
    comboBoxBlankSpaceForEmptyIcons: false
    comboBoxForcePressed: checked // latteView.visibility.mode === mode
    comboBoxPopUpAlignRight: Qt.application.layoutDirection !== Qt.RightToLeft
    comboBoxPopupTextHorizontalAlignment: Text.AlignHCenter

    property int mode: LatteCore.types.WindowsGoBelow
    readonly property int currentModeIndex: {
        for (var i=0; i<modes.length; ++i) {
            if (modes[i].pluginId === mode) {
                return i;
            }
        }

        return 0;
    }

    readonly property bool containsActiveMode: {
        for (var i=0; i<modes.length; ++i) {
            if (modes[i].pluginId === custom.latteView.visibility.mode) {
                return true;
            }
        }
        return false;
    }

    readonly property int firstVisibilityMode:  modes[0].pluginId
    readonly property int lastVisibilityMode: modes[modes.length - 1].pluginId

    property var modes: []

    signal viewRelevantVisibilityModeChanged();

    property bool _initializing: false

    Component.onCompleted: {
        _initializing = true;
        reloadModel();
        _initializing = false;
    }

    ListModel {
        id: actionsModel
    }

    Connections{
        target: custom.button
        function onClicked() {
            custom.latteView.visibility.mode = custom.mode;
        }
    }

    Connections{
        target: custom.comboBox.popup
        function onVisibleChanged() {
            if (custom.comboBox.popup.visible) {
                custom.selectChosenType();
            }
        }
    }

    Connections {
        target: custom.latteView.visibility
        function onModeChanged() {
            for (var i=0; i<custom.modes.length; ++i) {
                if (custom.modes[i].pluginId === custom.latteView.visibility.mode) {
                    custom.mode = custom.latteView.visibility.mode;
                    custom.viewRelevantVisibilityModeChanged();
                    return;
                }
            }
        }
    }

    Connections{
        target: custom.comboBox

        function onActivated(index) {
            if (index>=0) {
                var item = actionsModel.get(index);
                custom.latteView.visibility.mode = item.pluginId;
            }
        }

        function onCurrentIndexChanged() {
            if (custom._initializing) {
                return;
            }

            var idx = custom.comboBox.currentIndex;
            if (idx >= 0 && idx < actionsModel.count) {
                var item = actionsModel.get(idx);
                if (item && item.pluginId !== custom.latteView.visibility.mode) {
                    custom.latteView.visibility.mode = item.pluginId;
                }
            }
        }
    }

    function reloadModel() {
        actionsModel.clear();
        appendDefaults();
        comboBox.model = actionsModel;
        selectChosenType();
    }

    function selectChosenType() {
        var found = false;

        for (var i=0; i<actionsModel.count; ++i) {
            if (actionsModel.get(i).pluginId === custom.mode) {
                found = true;
                custom.comboBox.currentIndex = i;
                break;
            }
        }

        if (!found) {
            custom.comboBox.currentIndex = -1;
        }
    }

    function emptyModel() {
        actionsModel.clear();
        appendDefaults();

        comboBox.model = actionsModel;
        comboBox.currentIndex = -1;
    }

    function appendDefaults() {
        for (var i=0; i<modes.length; ++i) {
            actionsModel.append(modes[i]);
        }
    }
}
