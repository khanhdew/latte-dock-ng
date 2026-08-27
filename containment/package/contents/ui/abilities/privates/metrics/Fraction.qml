/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    // Default visual-proportion values; overridden by MetricsPrivate bindings.
    // Authoritative named constants are defined in:
    //   declarativeimports/abilities/definition/metrics/Constants.qml
    property real thicknessMargin: 0.06
    property real lengthMargin: 0.06
    property real lengthPadding: 0.06
    property real lengthAppletPadding: 0.06
}
