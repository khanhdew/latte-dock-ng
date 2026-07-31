/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <QAction>
#include <QPushButton>
#include <QSignalSpy>
#include <QTest>
#include <QVBoxLayout>
#include <QWidget>

#include <KMessageWidget>

#include "genericdialog.h"
#include "generichandler.h"

class TestGenericHandler : public Latte::Settings::Handler::Generic
{
    Q_OBJECT

public:
    using Latte::Settings::Handler::Generic::connectActionWithButton;
    using Latte::Settings::Handler::Generic::setTwinProperty;

    explicit TestGenericHandler(QObject *parent = nullptr)
        : Latte::Settings::Handler::Generic(nullptr, parent) {
    }

    bool hasChangedData() const override {
        return false;
    }

    bool inDefaultValues() const override {
        return true;
    }

public Q_SLOTS:
    void reset() override {}

    void resetDefaults() override {}

    void save() override {}
};

class GenericSettingsTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void handlerCopiesActionStateToButtonAndTriggersAction();
    void handlerMirrorsTwinActionPropertiesOnlyForKnownActions();
    void dialogSkipsInlineMessageWithoutTextOrLayout();
    void dialogCreatesPersistentInlineMessageWithActions();
    void dialogDeletesExistingInlineMessages();
};

void GenericSettingsTest::handlerCopiesActionStateToButtonAndTriggersAction()
{
    TestGenericHandler handler;
    QAction action(QStringLiteral("Apply Now"), &handler);
    action.setToolTip(QStringLiteral("Apply tooltip"));
    action.setWhatsThis(QStringLiteral("Apply help"));
    action.setIcon(QIcon::fromTheme(QStringLiteral("dialog-ok")));
    action.setCheckable(true);
    action.setChecked(true);

    QPushButton button;
    handler.connectActionWithButton(&button, &action);

    QCOMPARE(button.text(), action.text());
    QCOMPARE(button.toolTip(), action.toolTip());
    QCOMPARE(button.whatsThis(), action.whatsThis());
    QCOMPARE(button.isCheckable(), true);
    QCOMPARE(button.isChecked(), true);

    QSignalSpy triggeredSpy(&action, &QAction::triggered);
    button.click();
    QCOMPARE(triggeredSpy.count(), 1);
}

void GenericSettingsTest::handlerMirrorsTwinActionPropertiesOnlyForKnownActions()
{
    TestGenericHandler handler;
    QAction linkedAction(QStringLiteral("Linked"), &handler);
    linkedAction.setCheckable(true);
    linkedAction.setChecked(false);
    QPushButton linkedButton;
    handler.connectActionWithButton(&linkedButton, &linkedAction);

    handler.setTwinProperty(&linkedAction, QLatin1String(Latte::Settings::Handler::Generic::TWINVISIBLE), false);
    QCOMPARE(linkedAction.isVisible(), false);
    QCOMPARE(linkedButton.isVisible(), false);

    handler.setTwinProperty(&linkedAction, QLatin1String(Latte::Settings::Handler::Generic::TWINENABLED), false);
    QCOMPARE(linkedAction.isEnabled(), false);
    QCOMPARE(linkedButton.isEnabled(), false);

    handler.setTwinProperty(&linkedAction, QLatin1String(Latte::Settings::Handler::Generic::TWINCHECKED), true);
    QCOMPARE(linkedAction.isChecked(), true);
    QCOMPARE(linkedButton.isChecked(), true);

    QAction unknownAction(QStringLiteral("Unknown"), &handler);
    unknownAction.setVisible(true);
    handler.setTwinProperty(&unknownAction, QLatin1String(Latte::Settings::Handler::Generic::TWINVISIBLE), false);
    QCOMPARE(unknownAction.isVisible(), true);
}

void GenericSettingsTest::dialogSkipsInlineMessageWithoutTextOrLayout()
{
    Latte::Settings::Dialog::GenericDialog noLayoutDialog;
    noLayoutDialog.showInlineMessage(QStringLiteral("No layout"), KMessageWidget::Information, true);
    QCOMPARE(noLayoutDialog.findChildren<KMessageWidget *>().count(), 0);

    Latte::Settings::Dialog::GenericDialog dialog;
    auto *layout = new QVBoxLayout(&dialog);
    layout->addWidget(new QWidget(&dialog));

    dialog.showInlineMessage(QString(), KMessageWidget::Information, true);
    QCOMPARE(dialog.findChildren<KMessageWidget *>().count(), 0);
}

void GenericSettingsTest::dialogCreatesPersistentInlineMessageWithActions()
{
    Latte::Settings::Dialog::GenericDialog dialog;
    auto *layout = new QVBoxLayout(&dialog);
    layout->addWidget(new QWidget(&dialog));
    QAction action(QStringLiteral("Retry"), &dialog);

    dialog.showInlineMessage(QStringLiteral("Retry failed operation"), KMessageWidget::Warning, true, {&action});

    const auto messages = dialog.findChildren<KMessageWidget *>();
    QCOMPARE(messages.count(), 1);
    QCOMPARE(messages.first()->text(), QStringLiteral("Retry failed operation"));
    QCOMPARE(messages.first()->messageType(), KMessageWidget::Warning);
    QCOMPARE(messages.first()->actions().count(), 2);
    QCOMPARE(messages.first()->findChildren<QTimer *>().count(), 0);
}

void GenericSettingsTest::dialogDeletesExistingInlineMessages()
{
    Latte::Settings::Dialog::GenericDialog dialog;
    auto *layout = new QVBoxLayout(&dialog);
    layout->addWidget(new QWidget(&dialog));

    dialog.showInlineMessage(QStringLiteral("First"), KMessageWidget::Positive, true);
    dialog.showInlineMessage(QStringLiteral("Second"), KMessageWidget::Information, true);
    QCOMPARE(dialog.findChildren<KMessageWidget *>().count(), 2);

    dialog.deleteInlineMessages();
    QCOMPARE(dialog.findChildren<KMessageWidget *>().count(), 0);
}

QTEST_MAIN(GenericSettingsTest)

#include "genericsettingstest.moc"
