/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "lattepackage.h"

#include <KPackage/Package>
#include <KPackage/PackageLoader>

#include <QDir>
#include <QTemporaryDir>
#include <QTest>

class PackageUnitTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void lattePackageResolvesShellDefinitions();
    void indicatorPackageLoadsFromPluginAndResolvesDirectories();
    void indicatorPackageResolvesBundledDefaultIndicator();
};

void PackageUnitTest::lattePackageResolvesShellDefinitions()
{
    KPackage::Package package(new Latte::Package);
    package.setPath(QStringLiteral(LATTE_SOURCE_DIR "/shell/package"));

    QVERIFY(package.filePath("lattedockui").endsWith(QStringLiteral("views/Panel.qml")));
    QVERIFY(package.filePath("widgetexplorerui").endsWith(QStringLiteral("views/WidgetExplorer.qml")));
    QVERIFY(package.filePath("configmodel").endsWith(QStringLiteral("configuration/config.qml")));
    QVERIFY(package.filePath("templates").endsWith(QStringLiteral("templates")));
    QVERIFY(package.filePath("compactapplet").endsWith(QStringLiteral("applet/CompactApplet.qml")));
}

void PackageUnitTest::indicatorPackageLoadsFromPluginAndResolvesDirectories()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QStringList directories{
        QStringLiteral("config"),
        QStringLiteral("ui"),
        QStringLiteral("data"),
        QStringLiteral("code"),
        QStringLiteral("locale")
    };

    for (const QString &directory : directories) {
        QVERIFY(QDir(dir.path()).mkpath(QStringLiteral("contents/") + directory));
    }

    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Latte/Indicator"));
    package.setPath(dir.path());

    QVERIFY(package.filePath("config").endsWith(QStringLiteral("config")));
    QVERIFY(package.filePath("ui").endsWith(QStringLiteral("ui")));
    QVERIFY(package.filePath("data").endsWith(QStringLiteral("data")));
    QVERIFY(package.filePath("scripts").endsWith(QStringLiteral("code")));
    QVERIFY(package.filePath("translations").endsWith(QStringLiteral("locale")));
}

void PackageUnitTest::indicatorPackageResolvesBundledDefaultIndicator()
{
    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(
                                    QStringLiteral("Latte/Indicator"),
                                    QStringLiteral(LATTE_SOURCE_DIR "/indicators/default"));

    QVERIFY(package.isValid());
    QCOMPARE(package.metadata().pluginId(), QStringLiteral("org.kde.latte.default"));
    QCOMPARE(package.metadata().value(QStringLiteral("X-Latte-MainScript")), QStringLiteral("ui/main.qml"));
    QVERIFY(package.filePath("ui", QStringLiteral("main.qml")).endsWith(QStringLiteral("package/ui/main.qml")));
    QVERIFY(package.filePath("config", QStringLiteral("main.xml")).endsWith(QStringLiteral("package/config/main.xml")));
}

QTEST_GUILESS_MAIN(PackageUnitTest)

#include "packageunittest.moc"
