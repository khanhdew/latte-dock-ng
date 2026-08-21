/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15

BridgeItem {
    id: shortcutsBridge
    readonly property bool isConnected: host && client

    onClientChanged: {
        if (host && client) {
            if (host.appletIdStealingPositionShortcuts !== shortcutsBridge.appletIndex) {
                client.disabledIsStealingGlobalPositionShortcuts();
            }
        }
    }
    Connections {
        target: client
        function onIsStealingGlobalPositionShortcutsChanged() {
            if (isConnected && client.isStealingGlobalPositionShortcuts) {
                host.currentAppletStealingPositionShortcuts(appletIndex);
            }
        }
    }

    Connections {
        target: host
        function onSglActivateEntryAtIndex(entryIndex) {
            if (client) {
                client.sglActivateEntryAtIndex(entryIndex);
            }
        }

        function onSglNewInstanceForEntryAtIndex(entryIndex) {
            if (client) {
                client.sglNewInstanceForEntryAtIndex(entryIndex);
            }
        }

        function onCurrentAppletStealingPositionShortcuts(id) {
            if (appletIndex !== id && client) {
                client.disabledIsStealingGlobalPositionShortcuts();
            }
        }
    }
}
