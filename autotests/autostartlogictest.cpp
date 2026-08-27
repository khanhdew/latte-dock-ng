/*
    SPDX-FileCopyrightText: 2026 VerrPower <verrpower.4562@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <KConfigGroup>
#include <KDesktopFile>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QTest>

#include "../app/settings/autostart.h"

class AutostartLogicTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void missingEntryIsDisabled();
    void visibleEntryIsEnabled();
    void hiddenEntryIsDisabled();
    void enableCreatesEntryFromSource();
    void enableUnhidesEntryAndPreservesFields();
    void enableVisibleEntryIsIdempotent();
    void enableWithoutSourceFails();
    void enableWithInvalidDestinationFails();
    void disableMissingEntryIsIdempotent();
    void disableHidesEntryAndPreservesFields();
    void disableHiddenEntryIsIdempotent();

private:
    QString entryPath(const QTemporaryDir &configDir) const;
    void writeDesktopFile(const QString &path, const QByteArray &contents) const;
    QByteArray readFile(const QString &path) const;
};

QString AutostartLogicTest::entryPath(const QTemporaryDir &configDir) const
{
    return configDir.filePath(QStringLiteral("autostart/org.kde.latte-dock.desktop"));
}

void AutostartLogicTest::writeDesktopFile(const QString &path, const QByteArray &contents) const
{
    QVERIFY(QDir().mkpath(QFileInfo(path).absolutePath()));
    QFile file(path);
    QVERIFY(file.open(QFile::WriteOnly | QFile::Truncate));
    QCOMPARE(file.write(contents), qint64(contents.size()));
}

QByteArray AutostartLogicTest::readFile(const QString &path) const
{
    QFile file(path);
    if (!file.open(QFile::ReadOnly)) {
        return {};
    }
    return file.readAll();
}

void AutostartLogicTest::missingEntryIsDisabled()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    QVERIFY(!Latte::Autostart::isEnabled(entryPath(configDir)));
}

void AutostartLogicTest::visibleEntryIsEnabled()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    writeDesktopFile(path, "[Desktop Entry]\nType=Application\nHidden=false\n");
    QVERIFY(Latte::Autostart::isEnabled(path));
}

void AutostartLogicTest::hiddenEntryIsDisabled()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    writeDesktopFile(path, "[Desktop Entry]\nType=Application\nHidden=true\n");
    QVERIFY(!Latte::Autostart::isEnabled(path));
}

void AutostartLogicTest::enableCreatesEntryFromSource()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;
    QVERIFY(configDir.isValid());
    QVERIFY(sourceDir.isValid());

    const QString sourcePath = sourceDir.filePath(QStringLiteral("org.kde.latte-dock.desktop"));
    const QByteArray sourceContents{"[Desktop Entry]\nType=Application\nExec=/usr/bin/latte-dock-ng\nX-KDE-autostart-phase=2\n"};
    writeDesktopFile(sourcePath, sourceContents);

    const QString path = entryPath(configDir);
    QVERIFY(Latte::Autostart::enable(path, sourcePath));
    QCOMPARE(readFile(path), sourceContents);
    QVERIFY(Latte::Autostart::isEnabled(path));
}

void AutostartLogicTest::enableUnhidesEntryAndPreservesFields()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    writeDesktopFile(path,
                     "[Desktop Entry]\nType=Application\nHidden=true\nExec=/custom/latte\nX-Test=preserve\n");

    QVERIFY(Latte::Autostart::enable(path, QStringLiteral("/missing/source.desktop")));
    QVERIFY(Latte::Autostart::isEnabled(path));

    KDesktopFile desktopFile(path);
    const KConfigGroup desktopGroup = desktopFile.desktopGroup();
    QVERIFY(!desktopGroup.readEntry(QStringLiteral("Hidden"), true));
    QCOMPARE(desktopGroup.readEntry(QStringLiteral("Exec")), QStringLiteral("/custom/latte"));
    QCOMPARE(desktopGroup.readEntry(QStringLiteral("X-Test")), QStringLiteral("preserve"));
}

void AutostartLogicTest::enableVisibleEntryIsIdempotent()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    const QByteArray contents{"[Desktop Entry]\nType=Application\nExec=/custom/latte\n"};
    writeDesktopFile(path, contents);

    QVERIFY(Latte::Autostart::enable(path, QStringLiteral("/missing/source.desktop")));
    QCOMPARE(readFile(path), contents);
}

void AutostartLogicTest::enableWithoutSourceFails()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    QVERIFY(!Latte::Autostart::enable(path, QStringLiteral("/missing/source.desktop")));
    QVERIFY(!QFile::exists(path));
}

void AutostartLogicTest::enableWithInvalidDestinationFails()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;
    QVERIFY(configDir.isValid());
    QVERIFY(sourceDir.isValid());

    const QString sourcePath = sourceDir.filePath(QStringLiteral("source.desktop"));
    writeDesktopFile(sourcePath, "[Desktop Entry]\nType=Application\n");

    const QString blockingPath = configDir.filePath(QStringLiteral("not-a-directory"));
    writeDesktopFile(blockingPath, "blocking file\n");
    const QString destination = blockingPath + QStringLiteral("/entry.desktop");
    QVERIFY(!Latte::Autostart::enable(destination, sourcePath));
    QVERIFY(!QFile::exists(destination));
}

void AutostartLogicTest::disableMissingEntryIsIdempotent()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    QVERIFY(Latte::Autostart::disable(path));
    QVERIFY(!QFile::exists(path));
}

void AutostartLogicTest::disableHidesEntryAndPreservesFields()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    writeDesktopFile(path,
                     "[Desktop Entry]\nType=Application\nExec=/custom/latte\nX-Test=preserve\n");

    QVERIFY(Latte::Autostart::disable(path));
    QVERIFY(!Latte::Autostart::isEnabled(path));

    KDesktopFile desktopFile(path);
    const KConfigGroup desktopGroup = desktopFile.desktopGroup();
    QVERIFY(desktopGroup.readEntry(QStringLiteral("Hidden"), false));
    QCOMPARE(desktopGroup.readEntry(QStringLiteral("Exec")), QStringLiteral("/custom/latte"));
    QCOMPARE(desktopGroup.readEntry(QStringLiteral("X-Test")), QStringLiteral("preserve"));
}

void AutostartLogicTest::disableHiddenEntryIsIdempotent()
{
    QTemporaryDir configDir;
    QVERIFY(configDir.isValid());
    const QString path = entryPath(configDir);
    const QByteArray contents{"[Desktop Entry]\nType=Application\nHidden=true\nX-Test=preserve\n"};
    writeDesktopFile(path, contents);

    QVERIFY(Latte::Autostart::disable(path));
    QCOMPARE(readFile(path), contents);
}

QTEST_MAIN(AutostartLogicTest)
#include "autostartlogictest.moc"
