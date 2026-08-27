/*
    SPDX-FileCopyrightText: 2026 VerrPower <verrpower.4562@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "autostart.h"

#include <KConfigGroup>
#include <KDesktopFile>

#include <QDir>
#include <QFile>
#include <QFileInfo>

namespace Latte {
namespace Autostart {

bool isEnabled(const QString &entryPath)
{
    if (!QFile::exists(entryPath)) {
        return false;
    }

    KDesktopFile desktopFile(entryPath);
    return !desktopFile.desktopGroup().readEntry(QStringLiteral("Hidden"), false);
}

bool enable(const QString &entryPath, const QString &sourcePath)
{
    if (QFile::exists(entryPath)) {
        KDesktopFile desktopFile(entryPath);
        KConfigGroup desktopGroup = desktopFile.desktopGroup();

        if (!desktopGroup.readEntry(QStringLiteral("Hidden"), false)) {
            return true;
        }

        desktopGroup.writeEntry(QStringLiteral("Hidden"), false);
        return desktopGroup.sync();
    }

    const QFileInfo sourceInfo(sourcePath);

    if (!sourceInfo.isFile()) {
        return false;
    }

    if (!QDir().mkpath(QFileInfo(entryPath).absolutePath())) {
        return false;
    }

    return QFile::copy(sourcePath, entryPath);
}

bool disable(const QString &entryPath)
{
    if (!QFile::exists(entryPath)) {
        return true;
    }

    KDesktopFile desktopFile(entryPath);
    KConfigGroup desktopGroup = desktopFile.desktopGroup();

    if (desktopGroup.readEntry(QStringLiteral("Hidden"), false)) {
        return true;
    }

    desktopGroup.writeEntry(QStringLiteral("Hidden"), true);
    return desktopGroup.sync();
}

}
}
