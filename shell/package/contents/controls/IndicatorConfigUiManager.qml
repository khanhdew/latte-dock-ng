/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami 2.0 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: uiManager
    visible: false
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    readonly property color cfgBackgroundColor: (typeof dialog !== "undefined" && dialog && dialog.bC !== undefined) ? dialog.bC : systemPalette.window
    readonly property color cfgTextColor: (typeof dialog !== "undefined" && dialog && dialog.tC !== undefined) ? dialog.tC : systemPalette.windowText
    readonly property color cfgHighlightColor: (typeof dialog !== "undefined" && dialog && dialog.theme && dialog.theme.highlightColor !== undefined) ? dialog.theme.highlightColor : systemPalette.highlight
    readonly property color cfgHighlightedTextColor: (typeof dialog !== "undefined" && dialog && dialog.theme && dialog.theme.highlightedTextColor !== undefined) ? dialog.theme.highlightedTextColor : systemPalette.highlightedText

    Kirigami.Theme.backgroundColor: cfgBackgroundColor
    Kirigami.Theme.textColor: cfgTextColor
    Kirigami.Theme.highlightColor: cfgHighlightColor
    Kirigami.Theme.highlightedTextColor: cfgHighlightedTextColor


    property Item stackView: null

    Item {
        id: hiddenIndicatorPage
        anchors.fill: parent
        // Expose configuration dialog palette to dynamically loaded indicator
        // config pages via the "dialog" context property set from C++.
        property color bC: uiManager.cfgBackgroundColor
        property color tC: uiManager.cfgTextColor
        property color hC: uiManager.cfgHighlightColor
        property color htC: uiManager.cfgHighlightedTextColor
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.backgroundColor: uiManager.cfgBackgroundColor
        Kirigami.Theme.textColor: uiManager.cfgTextColor
        Kirigami.Theme.highlightColor: uiManager.cfgHighlightColor
        Kirigami.Theme.highlightedTextColor: uiManager.cfgHighlightedTextColor

        readonly property int optionsWidth: dialog.optionsWidth
        readonly property bool deprecatedOptionsAreHidden: true // @since 0.10.0

        readonly property Item nextPage: stackView.currentItem === page1 ? page2 : page1
        readonly property Item previousPage: nextPage === page1 ? page2 : page1

        function showNextIndicator() {
            var nextIndicator;

            //var pageShown = stackView.currentItem ? 1 : 0;
            //var total = page1.children.length + page2.children.length + hiddenPages.children.length + pageShown;
            //console.log(" org.kde.latte >>>>>>>>>>>>>>>>> ALL PAGES :: " + total);

            if (children.length > 0) {
                nextIndicator = children[0];
            }

            if (nextIndicator && (!stackView.currentItem || !stackView.currentItem.isCurrent)) {
                //!empty nextPage by moving its pages into hiddenPages
                var childrenCount = nextPage.children.length;
                for (var i=0; i<childrenCount; ++i) {
                    var previousIndicator = nextPage.children[0];
                    previousIndicator.visible = false;
                    previousIndicator.parent = hiddenPages;
                }

                nextIndicator.parent = nextPage;
                nextIndicator.visible = true;
                stackView.Layout.minimumHeight = nextIndicator.height;
                nextPage.type = latteView.indicator.type;

                var currentIndex = -1;

                if (stackView.currentItem) {
                    currentIndex = viewConfig.indicatorUiManager.index(stackView.currentItem.type);
                }

                var nextIndex = viewConfig.indicatorUiManager.index(latteView.indicator.type);

                stackView.forwardSliding = (nextIndex<currentIndex);
                stackView.replace(stackView.currentItem, nextPage);
            }

            if (children.length>0) {
                //!empty all remaining pages by moving them into hiddenPages
                var tempcount = children.length;
                for (var i=0; i<tempcount; ++i) {
                    var tempIndicator = children[0];
                    tempIndicator.visible = false;
                    tempIndicator.parent = hiddenPages;
                }
            }
        }

        Component.onCompleted: {
            viewConfig.indicatorUiManager.setParentItem(hiddenIndicatorPage);
            tabBar.selectTab(latteView.indicator.type);
            viewConfig.indicatorUiManager.ui(latteView.indicator.type, latteView);
        }

        Connections {
            target: latteView.indicator
            function onPluginChanged() {
                if (viewConfig.isReady) {
                    tabBar.selectTab(latteView.indicator.type);
                    viewConfig.indicatorUiManager.ui(latteView.indicator.type, latteView);
                }
            }
        }

        Connections {
            target: viewConfig
            function onIsReadyChanged() {
                if (viewConfig.isReady) {
                    tabBar.selectTab(latteView.indicator.type);
                    viewConfig.indicatorUiManager.ui(latteView.indicator.type, latteView);
                }
            }
        }
    }

    Item {
        id: hidden
        visible: false
        ColumnLayout {
            id: page1
            width: stackView.width
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.backgroundColor: uiManager.cfgBackgroundColor
            Kirigami.Theme.textColor: uiManager.cfgTextColor
            Kirigami.Theme.highlightColor: uiManager.cfgHighlightColor
            Kirigami.Theme.highlightedTextColor: uiManager.cfgHighlightedTextColor

            readonly property bool isCurrent: latteView.indicator.type === type && viewConfig.isReady/*update flag*/
            readonly property bool deprecatedOptionsAreHidden: true // @since 0.10.0
            readonly property int optionsWidth: dialog.optionsWidth

            property string type: ""
        }

        ColumnLayout {
            id: page2
            width: stackView.width
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.backgroundColor: uiManager.cfgBackgroundColor
            Kirigami.Theme.textColor: uiManager.cfgTextColor
            Kirigami.Theme.highlightColor: uiManager.cfgHighlightColor
            Kirigami.Theme.highlightedTextColor: uiManager.cfgHighlightedTextColor

            readonly property bool isCurrent: latteView.indicator.type === type && viewConfig.isReady/*update flag*/
            readonly property bool deprecatedOptionsAreHidden: true // @since 0.10.0
            readonly property int optionsWidth: dialog.optionsWidth

            property string type: ""
        }

        ColumnLayout {
            id: hiddenPages
            width: stackView.width
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.backgroundColor: uiManager.cfgBackgroundColor
            Kirigami.Theme.textColor: uiManager.cfgTextColor
            Kirigami.Theme.highlightColor: uiManager.cfgHighlightColor
            Kirigami.Theme.highlightedTextColor: uiManager.cfgHighlightedTextColor

            readonly property bool isCurrent: latteView.indicator.type === type && viewConfig.isReady/*update flag*/
            readonly property bool deprecatedOptionsAreHidden: true // @since 0.10.0
            readonly property int optionsWidth: dialog.optionsWidth

            property string type: ""
        }
    }
}
