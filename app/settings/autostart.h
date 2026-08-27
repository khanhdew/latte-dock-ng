/*
    SPDX-FileCopyrightText: 2026 VerrPower <verrpower.4562@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef AUTOSTART_H
#define AUTOSTART_H

#include <QString>

namespace Latte {
namespace Autostart {

bool isEnabled(const QString &entryPath);
bool enable(const QString &entryPath, const QString &sourcePath);
bool disable(const QString &entryPath);

}
}

#endif
