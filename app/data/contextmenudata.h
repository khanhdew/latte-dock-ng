/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef CONTEXTMENUDATA_H
#define CONTEXTMENUDATA_H

// Qt
#include <QStringList>

namespace Latte {
namespace Data {
namespace ContextMenu {

static const QString ADDVIEWACTION = QStringLiteral("_add_view");
static const QString ADDWIDGETSACTION = QStringLiteral("_add_latte_widgets");
static const QString DUPLICATEVIEWACTION = QStringLiteral("_duplicate_view"); /*used inside add view submenu*/
static const QString EDITVIEWACTION = QStringLiteral("_edit_view");
static const QString EXPORTVIEWTEMPLATEACTION = QStringLiteral("_export_view");
static const QString LAYOUTSACTION = QStringLiteral("_layouts");
static const QString MOVEVIEWACTION = QStringLiteral("_move_view");
static const QString PRINTACTION = QStringLiteral("_print");
static const QString PREFERENCESACTION = QStringLiteral("_preferences");
static const QString REMOVEVIEWACTION = QStringLiteral("_remove_view");
static const QString QUITLATTEACTION = QStringLiteral("_quit_latte");
static const QString SECTIONACTION = QStringLiteral("_latte_section");
static const QString SEPARATOR1ACTION = QStringLiteral("_separator1");

static QStringList ACTIONSEDITORDER = {LAYOUTSACTION,
                                       PREFERENCESACTION,
                                       QUITLATTEACTION,
                                       SEPARATOR1ACTION,
                                       ADDWIDGETSACTION,
                                       ADDVIEWACTION,
                                       MOVEVIEWACTION,
                                       EXPORTVIEWTEMPLATEACTION,
                                       REMOVEVIEWACTION
                                      };

static QStringList ACTIONSALWAYSVISIBLE = {LAYOUTSACTION,
                                           PREFERENCESACTION,
                                           QUITLATTEACTION,
                                           SEPARATOR1ACTION,
                                           ADDWIDGETSACTION,
                                           ADDVIEWACTION
                                          };

static QStringList ACTIONSALWAYSHIDDEN = {PRINTACTION};

static QStringList ACTIONSVISIBLEONLYINEDIT = {MOVEVIEWACTION,
                                               EXPORTVIEWTEMPLATEACTION,
                                               REMOVEVIEWACTION
                                              };

static QStringList ACTIONSSPECIAL = {SECTIONACTION,
                                     EDITVIEWACTION
                                    };

}
}
}

#endif
