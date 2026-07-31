/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <latte_debug.h>
#include "environment.h"

// Qt
#include <KConfigGroup>
#include <KDirWatch>
#include <KIconThemes/KIconLoader>
#include <KSharedConfig>
#include <QIcon>
#include <QDebug>
#include <QPixmapCache>
#include <QStandardPaths>

#define LONGDURATION 240
#define SHORTDURATION 40

namespace Latte{

const int Environment::SeparatorLength;

Environment::Environment(QObject *parent)
    : QObject(parent)
{
    const QString initialTheme = currentIconTheme();

    if (!initialTheme.isEmpty()) {
        QIcon::setThemeName(initialTheme);
    }

    // KF6: iconLoaderSettingsChanged is emitted whenever any icon setting
    // changes (theme, size, effects).  Previously iconChanged(int) was also
    // connected, but that signal fires once per icon group (Desktop, Toolbar,
    // MainToolbar …) and during theme switches caused a flood of QML binding
    // re-evaluations that could crash when Svg objects were being recreated.
    connect(KIconLoader::global(), &KIconLoader::iconLoaderSettingsChanged,
            this, &Environment::markIconThemeChanged);

    const QString kdeGlobalsFile = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/kdeglobals");

    if (!kdeGlobalsFile.isEmpty()) {
        KDirWatch::self()->addFile(kdeGlobalsFile);

        auto handleKdeGlobalsChange = [this, kdeGlobalsFile](const QString &path) {
            if (path != kdeGlobalsFile) {
                return;
            }

            QIcon::setThemeName(currentIconTheme());

            QPixmapCache::clear();
            qCDebug(latteQml) << "Environment::kdeglobals changed => reconfigure icon loader" << QIcon::themeName();
            KIconLoader::global()->reconfigure(QString());
            markIconThemeChanged();
        };

        connect(KDirWatch::self(), &KDirWatch::dirty, this, handleKdeGlobalsChange);
        connect(KDirWatch::self(), &KDirWatch::created, this, handleKdeGlobalsChange);
        connect(KDirWatch::self(), &KDirWatch::deleted, this, handleKdeGlobalsChange);

    m_iconThemeChangedTimer.setSingleShot(true);
    connect(&m_iconThemeChangedTimer, &QTimer::timeout, this, &Environment::emitIconThemeVersionChanged);
    }
}

int Environment::separatorLength() const
{
    return SeparatorLength;
}

uint Environment::shortDuration() const
{
    return SHORTDURATION;
}

uint Environment::longDuration() const
{
    return LONGDURATION;
}

uint Environment::iconThemeVersion() const
{
    return m_iconThemeVersion;
}

uint Environment::makeVersion(uint major, uint minor, uint release) const
{
    return (((major) << 16) | ((minor) << 8) | (release));
}

QVariant Environment::iconSourceForTheme(const QVariant &source) const
{
    if (source.canConvert<QIcon>()) {
        const QIcon icon = source.value<QIcon>();
        const QString iconName = icon.name();

        if (!iconName.isEmpty()) {
            return iconName;
        }
    }

    return source;
}

QString Environment::iconDescriptor(const QVariant &source) const
{
    QString descriptor = QString::fromLatin1(source.typeName() ? source.typeName() : "<unknown>");

    if (source.canConvert<QIcon>()) {
        const QIcon icon = source.value<QIcon>();
        descriptor += QStringLiteral(" iconName=\"%1\" isNull=%2")
                .arg(icon.name(), icon.isNull() ? QStringLiteral("true") : QStringLiteral("false"));
    }

    if (source.canConvert<QString>()) {
        descriptor += QStringLiteral(" string=\"%1\"").arg(source.toString());
    }

    return descriptor;
}

QString Environment::currentIconTheme() const
{
    KSharedConfigPtr kdeGlobals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    kdeGlobals->reparseConfiguration();
    KConfigGroup iconsGroup(kdeGlobals, QStringLiteral("Icons"));
    return iconsGroup.readEntry(QStringLiteral("Theme"), QStringLiteral("breeze"));
}

void Environment::markIconThemeChanged()
{
    // Debounce: rapid theme-change signals (e.g. from multiple icon groups
    // during a Plasma global-theme switch) can cause QML binding storms
    // that race with Svg object recreation.  Coalesce them into a single
    // notification per event-loop iteration.
    if (!m_iconThemeChangedTimer.isActive()) {
        m_iconThemeChangedTimer.start(50);
    }
}

void Environment::emitIconThemeVersionChanged()
{
    ++m_iconThemeVersion;
    qCDebug(latteQml) << "Environment::iconThemeVersionChanged" << m_iconThemeVersion;
    Q_EMIT iconThemeVersionChanged();
}

}
