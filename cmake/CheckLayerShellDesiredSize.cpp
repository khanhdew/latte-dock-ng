/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong@outlook.com>
    SPDX-License-Identifier: GPL-2.0-or-later

    CMake try_compile probe — detects whether LayerShellQt::Window exposes
    setDesiredSize(QSize), which was added in LayerShellQt 6.x (not present
    in the older liblayershellqtinterface shipped by Debian 13 Trixie).

    If this file compiles, CMake defines LATTE_LAYERSHELL_HAS_DESIRED_SIZE
    so that waylandinterface.cpp can conditionally call the method.
*/

#include <LayerShellQt/window.h>
#include <QSize>

int main()
{
    LayerShellQt::Window *w = nullptr;
    w->setDesiredSize(QSize(0, 0));
    return 0;
}
