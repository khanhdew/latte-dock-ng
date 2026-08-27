/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Qt
#include <QDir>
#include <QFileInfo>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <QtQml/qqml.h>
#include <QTest>

class PluginRegistrationUnitTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void containmentPluginRegistersTypes();
};

//! The plugin .so and its generated qmldir are staged into a temporary
//! import path and loaded by a real QML engine, asserting the same
//! contract as the former hand-written registerTypes(): the LayoutManager
//! type and the flat "types.<Value>" enum access used across the QML
//! sources keep working.
void PluginRegistrationUnitTest::containmentPluginRegistersTypes()
{
    QTemporaryDir importRoot;
    QVERIFY(importRoot.isValid());

    const QString modulePath = importRoot.path() + QStringLiteral("/org/kde/latte/private/containment");
    QVERIFY(QDir().mkpath(modulePath));

    const QString pluginFile = QStringLiteral(LATTE_CONTAINMENT_PLUGIN);
    QVERIFY(QFile::copy(QStringLiteral(LATTE_CONTAINMENT_QMLDIR), modulePath + QStringLiteral("/qmldir")));
    QVERIFY(QFile::copy(pluginFile, modulePath + QLatin1Char('/') + QFileInfo(pluginFile).fileName()));

    QQmlEngine engine;
    engine.addImportPath(importRoot.path());

    QQmlComponent component(&engine);
    component.setData(QByteArrayLiteral(
                          "import QtQml\n"
                          "import org.kde.latte.private.containment\n"
                          "QtObject {\n"
                          "    readonly property int scroll: types.ScrollNone\n"
                          "    property LayoutManager layout\n"
                          "}\n"),
                      QUrl(QStringLiteral("qrc:/containmentpluginregistrationtest.qml")));
    if (component.isError()) {
        qWarning() << component.errors();
    }
    QCOMPARE(component.status(), QQmlComponent::Ready);

    QVERIFY(qmlTypeId("org.kde.latte.private.containment", 0, 1, "LayoutManager") >= 0);
    QVERIFY(qmlTypeId("org.kde.latte.private.containment", 0, 1, "types") >= 0);
}

QTEST_GUILESS_MAIN(PluginRegistrationUnitTest)

#include "pluginregistrationunittest.moc"
