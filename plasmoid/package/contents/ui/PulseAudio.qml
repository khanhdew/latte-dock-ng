/*
    SPDX-FileCopyrightText: 2017 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.private.volume

QtObject {
    id: pulseAudio

    signal streamsChanged

    // It's a JS object so we can do key lookup and don't need to take care of filtering duplicates.
    property var pidMatches: ({})
    property var pidMatchTimestamps: ({})
    property var streamIndexes: ({})
    property bool streamIndexesDirty: true
    readonly property int pidMatchExpiryMs: 10 * 60 * 1000

    // A task can temporarily match an audio stream through its PID or app id
    // while its application name is not unique.  Keep that decision for a
    // bounded period, then allow the name fallback again after the stream has
    // disappeared.  Without expiry this cache grew for the entire session and
    // could permanently suppress a valid match for a later application.
    property Timer pidMatchCacheTimer: Timer {
        interval: 60 * 1000
        repeat: true
        running: false
        onTriggered: pulseAudio.prunePidMatches()
    }

    property int maxVolumePercent: 125
    property int maxVolumeValue: Math.round(maxVolumePercent * PulseAudio.NormalVolume / 100.0)
    property int volumeStep: Math.round(5 * PulseAudio.NormalVolume / 100.0)
    property int bootstrapAttempts: 0
    readonly property int bootstrapMaxAttempts: 5

    function boundVolume(volume) {
        return Math.max(PulseAudio.MinimalVolume, Math.min(volume, maxVolumeValue));
    }

    // Refresh the bounded cache entry while a task still has an audio stream.
    function registerPidMatch(appName) {
        pidMatchTimestamps[appName] = Date.now();
        pidMatchCacheTimer.start();

        if (!hasPidMatch(appName)) {
            pidMatches[appName] = true;

            // In case this match is new, notify that streams might have changed.
            // This way we also catch the case when the non-playing instance
            // shows up first.
            // Only notify if we changed to avoid infinite recursion.
            streamsChanged();
        }
    }

    function prunePidMatches() {
        var now = Date.now();
        var changed = false;

        for (var appName in pidMatchTimestamps) {
            if (now - pidMatchTimestamps[appName] > pidMatchExpiryMs) {
                delete pidMatchTimestamps[appName];
                delete pidMatches[appName];
                changed = true;
            }
        }

        if (changed) {
            streamsChanged();
        }

        if (Object.keys(pidMatchTimestamps).length === 0) {
            pidMatchCacheTimer.stop();
        }
    }

    function hasPidMatch(appName) {
        if (pidMatches[appName] !== true) {
            return false;
        }

        var timestamp = pidMatchTimestamps[appName];
        if (timestamp === undefined || Date.now() - timestamp > pidMatchExpiryMs) {
            delete pidMatches[appName];
            delete pidMatchTimestamps[appName];
            return false;
        }

        return true;
    }

    function normalizeId(value) {
        if (!value || value === "") {
            return "";
        }

        var normalized = String(value).toLowerCase();

        var slash = normalized.lastIndexOf("/");
        if (slash !== -1) {
            normalized = normalized.substring(slash + 1);
        }

        var colon = normalized.lastIndexOf(":");
        if (colon !== -1) {
            normalized = normalized.substring(colon + 1);
        }

        if (normalized.endsWith(".desktop")) {
            normalized = normalized.substring(0, normalized.length - 8);
        }

        // Reverse-DNS app ids such as org.mozilla.firefox or com.google.Chrome
        // should be comparable with launcher ids like firefox / chrome.
        var dot = normalized.lastIndexOf(".");
        if (dot !== -1 && dot < (normalized.length - 1)) {
            normalized = normalized.substring(dot + 1);
        }

        return normalized;
    }

    function equivalentId(left, right) {
        if (!left || !right) {
            return false;
        }

        if (left === right) {
            return true;
        }

        // Handle distro-specific suffix variants such as foo vs foo-esr.
        return left.startsWith(right + "-") || right.startsWith(left + "-");
    }

    function hasAncestorPid(streamPid, pid) {
        var current = streamPid;
        var depth = 0;

        while (current > 1 && depth < 16) {
            current = backend.parentPid(current);

            if (current === pid) {
                return true;
            }

            ++depth;
        }

        return false;
    }

    function addStreamToIndex(index, key, stream) {
        if (!key) {
            return;
        }

        if (!index[key]) {
            index[key] = [];
        }

        index[key].push(stream);
    }

    function rebuildStreamIndexes() {
        var indexes = {
            pid: Object.create(null),
            appId: Object.create(null),
            portalAppId: Object.create(null),
            appName: Object.create(null)
        };

        for (var i = 0, length = instantiator.count; i < length; ++i) {
            var stream = instantiator.objectAt(i);
            addStreamToIndex(indexes.pid, stream.pid > 0 ? String(stream.pid) : "", stream);
            addStreamToIndex(indexes.appId, stream.appId, stream);
            addStreamToIndex(indexes.portalAppId, stream.portalAppId, stream);
            addStreamToIndex(indexes.appName, stream.appName ? stream.appName.toLowerCase() : "", stream);
        }

        streamIndexes = indexes;
        streamIndexesDirty = false;
    }

    function ensureStreamIndexes() {
        if (streamIndexesDirty) {
            rebuildStreamIndexes();
        }
    }

    function findStreams(key, value) {
        ensureStreamIndexes();

        var index = streamIndexes[key];
        if (!index) {
            return [];
        }

        var lookupKey = key === "appName" ? String(value).toLowerCase() : String(value);
        return index[lookupKey] ? index[lookupKey].slice() : [];
    }

    function streamsForAppName(appName) {
        return findStreams("appName", appName);
    }

    function streamsForAppId(appId) {
        if (!appId || appId === "") {
            return [];
        }

        // Portal app id is the most reliable match for sandboxed/portal clients.
        var streams = findStreams("portalAppId", appId);

        if (streams.length === 0) {
            streams = findStreams("appId", appId);
        }

        return streams;
    }

    function streamsForPid(pid) {
        if (pid <= 0) {
            return [];
        }

        var streams = findStreams("pid", pid);

        if (streams.length === 0) {
            for (var i = 0, length = instantiator.count; i < length; ++i) {
                var stream = instantiator.objectAt(i);

                if (stream.parentPid === -1) {
                    stream.parentPid = backend.parentPid(stream.pid);
                }

                if (stream.parentPid === pid || hasAncestorPid(stream.parentPid, pid)) {
                    streams.push(stream);
                }
            }
        }

        return streams;
    }

    function streamsForAppIdentity(appId, launcherName, appName) {
        var idCandidates = [];
        var normalizedAppId = normalizeId(appId);
        var normalizedLauncherName = normalizeId(launcherName);
        var normalizedAppName = normalizeId(appName);

        if (normalizedAppId !== "") {
            idCandidates.push(normalizedAppId);
        }

        if (normalizedLauncherName !== "" && idCandidates.indexOf(normalizedLauncherName) === -1) {
            idCandidates.push(normalizedLauncherName);
        }

        if (normalizedAppName !== "" && idCandidates.indexOf(normalizedAppName) === -1) {
            idCandidates.push(normalizedAppName);
        }

        if (idCandidates.length === 0) {
            return [];
        }

        var streams = [];

        for (var i = 0, length = instantiator.count; i < length; ++i) {
            var stream = instantiator.objectAt(i);
            var streamCandidates = [
                normalizeId(stream.appId),
                normalizeId(stream.iconName),
                normalizeId(stream.binaryName),
                normalizeId(stream.appName)
            ];

            var matched = false;

            for (var c = 0; c < idCandidates.length && !matched; ++c) {
                var target = idCandidates[c];

                for (var s = 0; s < streamCandidates.length; ++s) {
                    if (equivalentId(target, streamCandidates[s])) {
                        matched = true;
                        break;
                    }
                }
            }

            if (matched) {
                streams.push(stream);
            }
        }

        return streams;
    }

    // Prime the SinkModel (output devices) so the Plasma volume applet gets
    // correct initial state when first added after a cold boot.  Without this
    // the sink subscription is only established on first consumer access,
    // which races with the async Plasma volume backend response. On modern
    // desktops this is commonly backed by PipeWire through pipewire-pulse,
    // while Plasma's private QML API still exposes PulseAudio-compatible names.
    // An Instantiator is needed to drive the model query — a bare  property var
    // creates the model but never triggers the initial data fetch.
    property Instantiator _sinkModelPrimer: Instantiator {
        model: SinkModel {}
        delegate: QtObject {}
    }

    // QtObject has no default property, hence adding the Instantiator to one explicitly.
    property Instantiator instantiator: Instantiator {
        model: PulseObjectFilterModel {
            filters: [ { role: "VirtualStream", value: false } ]
            sourceModel: SinkInputModel {}
        }

        delegate: QtObject {
            readonly property int pid: Client ? Client.properties["application.process.id"] : 0
            // Determined on demand.
            property int parentPid: -1
            readonly property string appName: (Client && Client.properties && Client.properties["application.name"] !== undefined)
                                              ? String(Client.properties["application.name"]) : ""
            readonly property string appId: (Client && Client.properties && Client.properties["application.id"] !== undefined)
                                            ? String(Client.properties["application.id"]) : ""
            readonly property string portalAppId: (Client && Client.properties && Client.properties["pipewire.access.portal.app_id"] !== undefined)
                                                  ? String(Client.properties["pipewire.access.portal.app_id"]) : ""
            readonly property string iconName: (Client && Client.properties && Client.properties["application.icon_name"] !== undefined)
                                               ? String(Client.properties["application.icon_name"]) : ""
            readonly property string binaryName: (Client && Client.properties && Client.properties["application.process.binary"] !== undefined)
                                                 ? String(Client.properties["application.process.binary"]) : ""
            readonly property bool muted: Muted
            // whether there is nothing actually going on on that stream
            readonly property bool corked: Corked

            readonly property int volume: Math.round(pulseVolume / PulseAudio.NormalVolume * 100.0)
            readonly property int pulseVolume: Volume

            function mute() {
                Muted = true
            }
            function unmute() {
                Muted = false
            }

            function increaseVolume() {
                var bVolume = pulseAudio.boundVolume(Volume + pulseAudio.volumeStep);
                Volume = bVolume;
            }

            function decreaseVolume() {
                var bVolume = pulseAudio.boundVolume(Volume - pulseAudio.volumeStep);
                Volume = bVolume;
            }
        }

        onObjectAdded: {
            pulseAudio.streamIndexesDirty = true;
            pulseAudio.streamsChanged();
        }
        onObjectRemoved: {
            pulseAudio.streamIndexesDirty = true;
            pulseAudio.streamsChanged();
        }
    }

    Component.onCompleted: {
        console.log("Plasma volume Latte interface was loaded...");
        bootstrapAttempts = 0;
        paFixTimer.start();
    }

    // ── Plasma volume PreferredDevice workaround ────────────────────────
    // PreferredDevice's constructor only connects to Server.defaultSinkChanged
    // — it never calls updatePreferredSink() initially.  If the Plasma volume
    // backend is already available when PreferredDevice is first created, the
    // signal never fires and PreferredDevice.sink stays null forever, causing
    // the volume applet to show a muted icon. PipeWire systems normally reach
    // this path through the pipewire-pulse compatibility service.
    //
    // We wait briefly for the Plasma volume context to be warm, then emit
    // defaultSinkChanged once on the Server singleton to force PreferredDevice
    // to call updatePreferredSink() and read the initial sink state.
    property Timer paFixTimer: Timer {
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            bootstrapAttempts++;

            try {
                var ds = Server.defaultSink
                if (ds && PreferredDevice) {
                    Server.defaultSinkChanged(ds)
                    paFixTimer.stop()
                    return;
                }
            } catch (e) {
                // Server/PreferredDevice not registered in this module version
            }

            if (bootstrapAttempts >= bootstrapMaxAttempts) {
                paFixTimer.stop();
            }
        }
    }
}
