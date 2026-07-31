/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "layoutmanager.h"

#include <QQuickItem>
#include <QSignalSpy>
#include <QTest>

class ContainmentLayoutUnitTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void tracksRequestedAppletOptionLists();
    void tracksScheduledDestructionIds();
    void restoresScheduledDestructionAppletAtOriginalIndex();
    void roundTripsMasqueradedIndexes();
    void scheduledDestructionHidesAndShowsAppletItem();
    void scheduledDestructionToleratesMissingLayouts();
};

void ContainmentLayoutUnitTest::tracksRequestedAppletOptionLists()
{
    Latte::Containment::LayoutManager manager;
    QSignalSpy lockedSpy(&manager, &Latte::Containment::LayoutManager::lockedZoomAppletsChanged);
    QSignalSpy coloringSpy(&manager, &Latte::Containment::LayoutManager::userBlocksColorizingAppletsChanged);

    manager.requestAppletsInLockedZoom(QList<int> {3, 5});
    manager.requestAppletsInLockedZoom(QList<int> {3, 5});
    QCOMPARE(manager.lockedZoomApplets(), (QList<int> {3, 5}));
    QCOMPARE(lockedSpy.count(), 1);

    manager.requestAppletsDisabledColoring(QList<int> {7});
    manager.requestAppletsDisabledColoring(QList<int> {7});
    QCOMPARE(manager.userBlocksColorizingApplets(), (QList<int> {7}));
    QCOMPARE(coloringSpy.count(), 1);
}

void ContainmentLayoutUnitTest::tracksScheduledDestructionIds()
{
    Latte::Containment::LayoutManager manager;
    QSignalSpy scheduledSpy(&manager, &Latte::Containment::LayoutManager::appletsInScheduledDestructionChanged);

    manager.setAppletInScheduledDestruction(9, true);
    manager.setAppletInScheduledDestruction(9, true);
    QVERIFY(manager.appletsInScheduledDestruction().contains(9));
    QCOMPARE(scheduledSpy.count(), 1);

    manager.setAppletInScheduledDestruction(9, false);
    manager.setAppletInScheduledDestruction(9, false);
    QVERIFY(!manager.appletsInScheduledDestruction().contains(9));
    QCOMPARE(scheduledSpy.count(), 2);
}

void ContainmentLayoutUnitTest::restoresScheduledDestructionAppletAtOriginalIndex()
{
    Latte::Containment::LayoutManager manager;

    manager.requestAppletsOrder(QList<int> {1, 2, 3, 4});

    QVERIFY(QMetaObject::invokeMethod(&manager,
                                      "rememberAppletRemovalIndex",
                                      Qt::DirectConnection,
                                      Q_ARG(int, 2)));

    manager.requestAppletsOrder(QList<int> {1, 3, 4});

    QVERIFY(QMetaObject::invokeMethod(&manager,
                                      "restoreAppletOrderForApplet",
                                      Qt::DirectConnection,
                                      Q_ARG(int, 2)));

    QCOMPARE(manager.appletOrder(), (QList<int> {1, 2, 3, 4}));
}

void ContainmentLayoutUnitTest::roundTripsMasqueradedIndexes()
{
    Latte::Containment::LayoutManager manager;

    const QPoint encoded = manager.indexToMasquearadedPoint(12);
    QVERIFY(manager.isMasqueradedIndex(encoded.x(), encoded.y()));
    QCOMPARE(manager.masquearadedIndex(encoded.x(), encoded.y()), 12);
    QVERIFY(!manager.isMasqueradedIndex(encoded.x(), encoded.y() + 1));
}

void ContainmentLayoutUnitTest::scheduledDestructionHidesAndShowsAppletItem()
{
    Latte::Containment::LayoutManager manager;

    // Stack-allocated layout and applet item — QQuickItem can be
    // stack-allocated when no QObject parent is needed.
    QQuickItem mainLayout;
    manager.setMainLayout(&mainLayout);

    // Mock backend object: a plain QObject whose "id" property is the
    // target applet id (appletId() reads candidate->property("id")).
    constexpr int testId{42};
    QObject backend;
    backend.setProperty("id", testId);

    // Applet item — the item whose visibility we want to verify.
    // The visual parent (mainLayout) is also the QObject parent, so
    // appletItem appears in mainLayout.childItems().
    QQuickItem appletItem(&mainLayout);
    appletItem.setProperty("applet", QVariant::fromValue(static_cast<QObject *>(&backend)));
    appletItem.setVisible(true);
    QVERIFY(appletItem.isVisible());

    QSignalSpy scheduledSpy(&manager, &Latte::Containment::LayoutManager::appletsInScheduledDestructionChanged);

    // Schedule destruction — the item should be hidden immediately.
    manager.setAppletInScheduledDestruction(testId, true);
    QVERIFY(manager.appletsInScheduledDestruction().contains(testId));
    QVERIFY(!appletItem.isVisible());
    QCOMPARE(scheduledSpy.count(), 1);

    // Redundant enable — no change, no extra signal.
    manager.setAppletInScheduledDestruction(testId, true);
    QVERIFY(manager.appletsInScheduledDestruction().contains(testId));
    QCOMPARE(scheduledSpy.count(), 1);

    // Undo — the item should become visible again.
    manager.setAppletInScheduledDestruction(testId, false);
    QVERIFY(!manager.appletsInScheduledDestruction().contains(testId));
    QVERIFY(appletItem.isVisible());
    QCOMPARE(scheduledSpy.count(), 2);

    // Redundant disable — no change, no extra signal.
    manager.setAppletInScheduledDestruction(testId, false);
    QVERIFY(!manager.appletsInScheduledDestruction().contains(testId));
    QCOMPARE(scheduledSpy.count(), 2);
}

void ContainmentLayoutUnitTest::scheduledDestructionToleratesMissingLayouts()
{
    Latte::Containment::LayoutManager manager;
    QSignalSpy scheduledSpy(&manager, &Latte::Containment::LayoutManager::appletsInScheduledDestructionChanged);

    // No layouts set — appletItem() returns nullptr.
    // The function must not crash and must still track IDs correctly.
    manager.setAppletInScheduledDestruction(7, true);
    QVERIFY(manager.appletsInScheduledDestruction().contains(7));
    QCOMPARE(scheduledSpy.count(), 1);

    manager.setAppletInScheduledDestruction(7, false);
    QVERIFY(!manager.appletsInScheduledDestruction().contains(7));
    QCOMPARE(scheduledSpy.count(), 2);
}



QTEST_MAIN(ContainmentLayoutUnitTest)

#include "containmentlayoutunittest.moc"
