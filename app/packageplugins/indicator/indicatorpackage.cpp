/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "indicatorpackage.h"

// Qt
#include <QDebug>

// KDE
#include <KPackage/PackageLoader>
//! K_PLUGIN_CLASS_WITH_JSON below must see the macro definition from
//! kpluginfactory.h. On Qt 6.8 moc does not expand the macro chain, and
//! the compat/KPackage/PackageStructure forwarding header resolves to a
//! header that does not pull kpluginfactory.h in, so without this include
//! the plugin ships without embedded metadata and KPackage cannot resolve
//! the "Latte/Indicator" structure. Qt 6.10+ generates plugin metadata in
//! the compiler, which is why the failure only showed up on older Qt.
#include <KPluginFactory>
#include <KLocalizedString>

namespace Latte {

IndicatorPackage::IndicatorPackage(QObject *parent, const QVariantList &args)
    : KPackage::PackageStructure(parent, args)
{
}

void IndicatorPackage::initPackage(KPackage::Package *package)
{
    package->setDefaultPackageRoot(QStringLiteral("latte/indicators"));
    package->setContentsPrefixPaths({QStringLiteral("package"), QStringLiteral("contents")});

    package->addDirectoryDefinition("config", QStringLiteral("config"));
    package->addDirectoryDefinition("ui", QStringLiteral("ui"));
    package->addDirectoryDefinition("data", QStringLiteral("data"));
    package->addDirectoryDefinition("scripts", QStringLiteral("code"));
    package->addDirectoryDefinition("translations", QStringLiteral("locale"));
}

}

K_PLUGIN_CLASS_WITH_JSON(Latte::IndicatorPackage, "latte-packagestructure-indicator.json")

#include "indicatorpackage.moc"
