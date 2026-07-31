/*
    SPDX-FileCopyrightText: 2016 Smith AR <audoban@openmailbox.org>
    SPDX-FileCopyrightText: 2016 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.ksvg 1.0 as KSvg

KSvg.FrameSvgItem {
    id: root

    // Latte draws dock background inside the containment itself.
    imagePath: ""
    prefix: ""

    property Item containment
    property Item viewLayout

    /*  Rectangle{
        anchors.fill: parent
        color: "transparent"
        border.color: "blue"
        border.width: 1
    }*/

    Component.onDestruction: {
        console.log("latte view qml source deleting...");
    }

    onContainmentChanged: {
        console.log("latte view qml source - containment changed 1...");
        if (!containment) {
            return;
        }
        console.log("latte view qml source - containment changed 2...");

        containment.parent = containmentParent;
        containment.visible = true;
        containment.anchors.fill = containmentParent;
        for(var i=0; i<containment.children.length; ++i){
            if (containment.children[i].objectName === "containmentViewLayout") {
                viewLayout = containment.children[i];
            }
        }
    }

    Item {
        id: containmentParent
        anchors.fill: parent
    }

    //! it is used in order to check the right click position
    //! the only way to take into account the visual appearance
    //! of the applet (including its spacers)
    function appletContainsPos(appletId, pos) {
        if (viewLayout) {
            return viewLayout.appletContainsPos(appletId, pos);
        }

        return false;
    }
}
