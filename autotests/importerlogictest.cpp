/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <KConfigGroup>
#include <KSharedConfig>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QTest>

// Replicates static helper logic from app/layouts/importer.cpp

namespace ImporterLogic {

enum FileVersion { Unknown = -1, LayoutV2 = 2, ConfigV2 = 3 };

QString nameOfConfigFile(const QString &fileName)
{
    int lastSlash = fileName.lastIndexOf(QLatin1Char('/'));
    QString temp = fileName;
    QString layoutName = temp.remove(0, lastSlash + 1);
    int ext = layoutName.lastIndexOf(QStringLiteral(".latterc"));
    return (ext >= 0) ? layoutName.remove(ext, 8) : layoutName;
}

FileVersion fileVersion(const QString &file, KSharedConfig::Ptr config = {})
{
    auto cfg = config ? config : KSharedConfig::openConfig(file);

    if (!QFile::exists(file))
        return Unknown;

    if (file.endsWith(QStringLiteral(".layout.latte"))) {
        KConfigGroup lg(cfg, QStringLiteral("LayoutSettings"));
        int v = lg.readEntry(QStringLiteral("version"), 1);
        return (v == 2) ? LayoutV2 : Unknown;
    }

    if (file.endsWith(QStringLiteral(".latterc"))) {
        KConfigGroup lg(cfg, QStringLiteral("LayoutSettings"));
        int v = lg.readEntry(QStringLiteral("version"), 1);
        return (v == 2) ? ConfigV2 : Unknown;
    }

    return Unknown;
}

QString layoutUserFilePath(const QString &layoutName)
{
    return layoutName.isEmpty() ? QString()
           : QStringLiteral("/tmp/latte-test/latte/") + layoutName + QStringLiteral(".layout.latte");
}

//! Replicates the autostart management logic from Importer::isAutostartEnabled /
//! enableAutostart / disableAutostart, operating on a caller-provided config
//! directory so tests can use QTemporaryDir without touching the real ~/.config.

static const char *const kAutostartFileName = "org.kde.latte-dock.desktop";
static const char *const kDeprecatedFileName = "latte-dock.desktop";

QString autostartFilePath(const QString &configDir)
{
    return configDir + QStringLiteral("/autostart/") + QString::fromLatin1(kAutostartFileName);
}

QString deprecatedAutostartFilePath(const QString &configDir)
{
    return configDir + QStringLiteral("/autostart/") + QString::fromLatin1(kDeprecatedFileName);
}

bool isAutostartEnabled(const QString &configDir)
{
    return QFile::exists(autostartFilePath(configDir));
}

void enableAutostart(const QString &configDir, const QString &sourceDesktopFile)
{
    //! Remove deprecated file
    QFile deprecated(deprecatedAutostartFilePath(configDir));

    if (deprecated.exists()) {
        deprecated.remove();
    }

    const QString autostartFile = autostartFilePath(configDir);
    const QString autostartDir = configDir + QStringLiteral("/autostart");

    if (!sourceDesktopFile.isEmpty() && QFile::exists(sourceDesktopFile)) {
        QDir().mkpath(autostartDir);

        if (QFile::exists(autostartFile)) {
            //! Update when source is newer (upgrade path)
            QFileInfo autostartInfo(autostartFile);
            QFileInfo sourceInfo(sourceDesktopFile);

            if (autostartInfo.lastModified() >= sourceInfo.lastModified()) {
                return; // up to date
            }

            //! Stage the replacement next to the working file so a failed
            //! copy can never delete the autostart entry.
            const QString stagedFile = autostartFile + QStringLiteral(".new");
            QFile::remove(stagedFile);

            if (QFile::copy(sourceDesktopFile, stagedFile)) {
                QFile::remove(autostartFile);
                QFile::rename(stagedFile, autostartFile);
            } else {
                QFile::remove(stagedFile);
            }
            return;
        }

        QFile::copy(sourceDesktopFile, autostartFile);
    }
}

void disableAutostart(const QString &configDir)
{
    QFile deprecated(deprecatedAutostartFilePath(configDir));

    if (deprecated.exists()) {
        deprecated.remove();
    }

    QFile autostartFile(autostartFilePath(configDir));

    if (autostartFile.exists()) {
        autostartFile.remove();
    }
}

} // namespace ImporterLogic

class ImporterLogicTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void nameStripsPathAndExtension();
    void nameWithNoExtensionPreserved();
    void nameFromEmptyString();

    void unknownFileTypeForNonexistent();
    void layoutV2Recognized();
    void layoutV1IsUnknown();

    void userFilePathEndsWithExtension();
    void emptyNameProducesEmptyPath();

    // Autostart management tests
    void autostartNotEnabledWhenFileMissing();
    void autostartEnabledWhenFileExists();
    void enableCreatesAutostartFile();
    void enableWithEmptySourceDoesNothing();
    void disableRemovesAutostartFile();
    void disableDoesNothingWhenFileMissing();
    void enableRemovesDeprecatedFile();
    void enableUpdatesOutdatedAutostartFile();
    void enableSkipsWhenUpToDate();
    void updatePreservesExistingFileWhenCopyFails();
    void enableWithMissingSourceKeepsExistingFile();
};

void ImporterLogicTest::nameStripsPathAndExtension()
{
    QCOMPARE(ImporterLogic::nameOfConfigFile(QStringLiteral("/home/user/myconfig.latterc")),
             QStringLiteral("myconfig"));
    QCOMPARE(ImporterLogic::nameOfConfigFile(QStringLiteral("dock.latterc")),
             QStringLiteral("dock"));
}

void ImporterLogicTest::nameWithNoExtensionPreserved()
{
    QCOMPARE(ImporterLogic::nameOfConfigFile(QStringLiteral("/path/justname")),
             QStringLiteral("justname"));
}

void ImporterLogicTest::nameFromEmptyString()
{
    QCOMPARE(ImporterLogic::nameOfConfigFile(QString()), QString());
}

void ImporterLogicTest::unknownFileTypeForNonexistent()
{
    QCOMPARE(ImporterLogic::fileVersion(QStringLiteral("/nonexistent.layout.latte")),
             ImporterLogic::Unknown);
}

void ImporterLogicTest::layoutV2Recognized()
{
    QTemporaryDir dir;
    const QString path = dir.path() + QStringLiteral("/v2.layout.latte");
    auto cfg = KSharedConfig::openConfig(path);
    KConfigGroup(cfg, QStringLiteral("LayoutSettings")).writeEntry(QStringLiteral("version"), 2);
    cfg->sync();
    QCOMPARE(ImporterLogic::fileVersion(path, cfg), ImporterLogic::LayoutV2);
}

void ImporterLogicTest::layoutV1IsUnknown()
{
    QTemporaryDir dir;
    const QString path = dir.path() + QStringLiteral("/v1.layout.latte");
    auto cfg = KSharedConfig::openConfig(path);
    KConfigGroup(cfg, QStringLiteral("LayoutSettings")).writeEntry(QStringLiteral("version"), 1);
    cfg->sync();
    QCOMPARE(ImporterLogic::fileVersion(path, cfg), ImporterLogic::Unknown);
}

void ImporterLogicTest::userFilePathEndsWithExtension()
{
    const QString path = ImporterLogic::layoutUserFilePath(QStringLiteral("MyDock"));
    QVERIFY(path.endsWith(QStringLiteral("/MyDock.layout.latte")));
}

void ImporterLogicTest::emptyNameProducesEmptyPath()
{
    QVERIFY(ImporterLogic::layoutUserFilePath(QString()).isEmpty());
}

// --- autostart management tests ---

void ImporterLogicTest::autostartNotEnabledWhenFileMissing()
{
    QTemporaryDir configDir;
    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::autostartEnabledWhenFileExists()
{
    QTemporaryDir configDir;
    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    QFile f(ImporterLogic::autostartFilePath(configDir.path()));
    QVERIFY(f.open(QFile::WriteOnly));
    f.write("[Desktop Entry]\n");
    f.close();

    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::enableCreatesAutostartFile()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    // Create a source desktop file
    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    QFile source(sourcePath);
    QVERIFY(source.open(QFile::WriteOnly));
    source.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\nX-KDE-autostart-phase=2\n");
    source.close();

    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
    ImporterLogic::enableAutostart(configDir.path(), sourcePath);
    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));

    // Verify the content was copied
    QFile copied(ImporterLogic::autostartFilePath(configDir.path()));
    QVERIFY(copied.open(QFile::ReadOnly));
    const QString content = QString::fromUtf8(copied.readAll());
    QVERIFY(content.contains(QStringLiteral("X-KDE-autostart-phase=2")));
}

void ImporterLogicTest::enableWithEmptySourceDoesNothing()
{
    QTemporaryDir configDir;
    ImporterLogic::enableAutostart(configDir.path(), QString());
    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::disableRemovesAutostartFile()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    QFile source(sourcePath);
    QVERIFY(source.open(QFile::WriteOnly));
    source.write("[Desktop Entry]\n");
    source.close();

    ImporterLogic::enableAutostart(configDir.path(), sourcePath);
    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));

    ImporterLogic::disableAutostart(configDir.path());
    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::disableDoesNothingWhenFileMissing()
{
    QTemporaryDir configDir;
    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
    // Should not crash
    ImporterLogic::disableAutostart(configDir.path());
    QVERIFY(!ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::enableRemovesDeprecatedFile()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    // Create a deprecated autostart file
    QFile deprecated(configDir.path() + QStringLiteral("/autostart/latte-dock.desktop"));
    QVERIFY(deprecated.open(QFile::WriteOnly));
    deprecated.write("[Desktop Entry]\n");
    deprecated.close();
    QVERIFY(deprecated.exists());

    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    QFile source(sourcePath);
    QVERIFY(source.open(QFile::WriteOnly));
    source.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\n");
    source.close();

    ImporterLogic::enableAutostart(configDir.path(), sourcePath);

    // Deprecated file should be removed
    QVERIFY(!deprecated.exists());
    // New file should be created
    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));
}

void ImporterLogicTest::enableUpdatesOutdatedAutostartFile()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    // Create a source file (simulating a freshly installed system desktop file)
    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    {
        QFile source(sourcePath);
        QVERIFY(source.open(QFile::WriteOnly));
        source.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\nX-KDE-autostart-phase=2\n");
        source.close();
    }

    // Create an OLD autostart file (simulating pre-upgrade state without X-KDE-autostart-phase)
    const QString autostartPath = ImporterLogic::autostartFilePath(configDir.path());
    {
        QFile old(autostartPath);
        QVERIFY(old.open(QFile::WriteOnly));
        old.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\n");
        old.close();
    }

    // Make the source file newer by touching it after a short sleep
    QTest::qSleep(100);
    QFile source(sourcePath);
    QVERIFY(source.open(QFile::Append));
    source.write("# updated\n");
    source.close();

    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));

    // enableAutostart should detect the outdated file and update it
    ImporterLogic::enableAutostart(configDir.path(), sourcePath);

    QFile updated(autostartPath);
    QVERIFY(updated.open(QFile::ReadOnly));
    const QString content = QString::fromUtf8(updated.readAll());
    QVERIFY(content.contains(QStringLiteral("X-KDE-autostart-phase=2")));
    QVERIFY(content.contains(QStringLiteral("# updated")));
}

void ImporterLogicTest::enableSkipsWhenUpToDate()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    {
        QFile source(sourcePath);
        QVERIFY(source.open(QFile::WriteOnly));
        source.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\n");
        source.close();
    }

    // First enable: creates the autostart file
    ImporterLogic::enableAutostart(configDir.path(), sourcePath);
    QVERIFY(ImporterLogic::isAutostartEnabled(configDir.path()));

    // Get the modification time after first enable
    QFileInfo firstInfo(ImporterLogic::autostartFilePath(configDir.path()));
    const QDateTime firstMtime = firstInfo.lastModified();

    // Source file hasn't changed; second enable should skip
    QTest::qSleep(100);
    ImporterLogic::enableAutostart(configDir.path(), sourcePath);

    QFileInfo secondInfo(ImporterLogic::autostartFilePath(configDir.path()));
    // File should NOT have been modified (skipped because up-to-date)
    QCOMPARE(secondInfo.lastModified(), firstMtime);
}

void ImporterLogicTest::updatePreservesExistingFileWhenCopyFails()
{
    QTemporaryDir configDir;
    QTemporaryDir sourceDir;

    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    // Create the existing autostart entry first, then a newer source file
    const QString autostartPath = ImporterLogic::autostartFilePath(configDir.path());
    {
        QFile old(autostartPath);
        QVERIFY(old.open(QFile::WriteOnly));
        old.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\nOLD CONTENT\n");
        old.close();
    }
    QTest::qSleep(1100);

    // Create a source file that is newer than the existing autostart entry
    const QString sourcePath = sourceDir.path() + QStringLiteral("/org.kde.latte-dock.desktop");
    {
        QFile source(sourcePath);
        QVERIFY(source.open(QFile::WriteOnly));
        source.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\nX-KDE-autostart-phase=2\n");
        source.close();
    }

    // Make the source unreadable so the replacement copy fails
    QFile source(sourcePath);
    QVERIFY(source.setPermissions(QFileDevice::Permissions()));

    ImporterLogic::enableAutostart(configDir.path(), sourcePath);

    // A failed update must never delete the working autostart entry
    QFile kept(autostartPath);
    QVERIFY(kept.exists());
    QVERIFY(kept.open(QFile::ReadOnly));
    const QString content = QString::fromUtf8(kept.readAll());
    QVERIFY(content.contains(QStringLiteral("OLD CONTENT")));
}

void ImporterLogicTest::enableWithMissingSourceKeepsExistingFile()
{
    QTemporaryDir configDir;

    const QString autostartDir = configDir.path() + QStringLiteral("/autostart");
    QDir().mkpath(autostartDir);

    const QString autostartPath = ImporterLogic::autostartFilePath(configDir.path());
    {
        QFile old(autostartPath);
        QVERIFY(old.open(QFile::WriteOnly));
        old.write("[Desktop Entry]\nExec=/usr/bin/latte-dock-ng\nOLD CONTENT\n");
        old.close();
    }

    // A missing source (e.g. package temporarily uninstalled) must not
    // remove the existing autostart entry.
    ImporterLogic::enableAutostart(configDir.path(),
                                   QStringLiteral("/nonexistent/org.kde.latte-dock.desktop"));

    QFile kept(autostartPath);
    QVERIFY(kept.exists());
}

QTEST_MAIN(ImporterLogicTest)
#include "importerlogictest.moc"
