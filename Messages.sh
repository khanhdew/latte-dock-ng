#! /usr/bin/env bash
$EXTRACTRC `find app -name \*.rc -o -name \*.ui` >> rc.cpp

# declarativeimports (LatteComponents, abilities) is scanned into the
# application catalog: these shared QML components execute inside the
# settings windows whose translation domain is the application domain.
$XGETTEXT `find app shell declarativeimports rc.cpp -name \*.js -o -name \*.qml -o -name \*.cpp` -o $podir/latte-dock.pot
