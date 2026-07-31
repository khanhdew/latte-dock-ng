/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "panelshadows_p.h"

#include <QSignalSpy>
#include <QTest>
#include <QWindow>

class PanelShadowUnitTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void singletonReturnsStableInstance();
    void ignoresNullWindowsAndAllowsRepeatedRemoval();
    void tracksWindowUntilDestroyed();
};

void PanelShadowUnitTest::singletonReturnsStableInstance()
{
    QVERIFY(PanelShadows::self());
    QCOMPARE(PanelShadows::self(), PanelShadows::self());
}

void PanelShadowUnitTest::ignoresNullWindowsAndAllowsRepeatedRemoval()
{
    PanelShadows shadows(nullptr, QStringLiteral("missing/panel-shadow-test"));

    shadows.addWindow(nullptr);
    shadows.setEnabledBorders(nullptr, KSvg::FrameSvg::NoBorder);
    shadows.removeWindow(nullptr);
}

void PanelShadowUnitTest::tracksWindowUntilDestroyed()
{
    PanelShadows shadows(nullptr, QStringLiteral("missing/panel-shadow-test"));
    auto *window = new QWindow;
    QSignalSpy destroyedSpy(window, &QObject::destroyed);

    shadows.addWindow(window, KSvg::FrameSvg::TopBorder | KSvg::FrameSvg::BottomBorder);
    shadows.setEnabledBorders(window, KSvg::FrameSvg::LeftBorder | KSvg::FrameSvg::RightBorder);
    shadows.removeWindow(window);
    shadows.removeWindow(window);

    delete window;
    QCOMPARE(destroyedSpy.count(), 1);
}

QTEST_MAIN(PanelShadowUnitTest)

#include "panelshadowunittest.moc"
