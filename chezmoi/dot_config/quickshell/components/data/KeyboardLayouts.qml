pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var layoutNames: []
    property int currentIndex: -1
    property string currentName: root.currentIndex >= 0 && root.currentIndex < root.layoutNames.length ? root.layoutNames[root.currentIndex] : ""
    property string currentShortLabel: root.toShortLabel(root.currentName)

    function refresh() {
        layoutQuery.exec(["niri", "msg", "-j", "keyboard-layouts"]);
    }

    function switchNext() {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
        refreshDelay.restart();
    }

    function applyLayoutState(rawText) {
        const raw = rawText.trim();

        if (raw === "") {
            return;
        }

        try {
            const parsed = JSON.parse(raw);
            root.layoutNames = parsed.names || [];
            root.currentIndex = typeof parsed.current_idx === "number" ? parsed.current_idx : -1;
        } catch (error) {
            console.warn("Failed to parse niri keyboard layouts:", error);
        }
    }

    function toShortLabel(layoutName) {
        if (!layoutName || layoutName.trim() === "") {
            return "--";
        }

        const name = layoutName.trim().toLowerCase();
        const aliases = {
            "english (us)": "EN",
            "german": "DE"
        };

        if (aliases[name]) {
            return aliases[name];
        }

        const firstToken = layoutName.replace(/\(.*\)/g, "").trim().split(/\s+/)[0];
        if (!firstToken) {
            return "--";
        }

        return firstToken.slice(0, 2).toUpperCase();
    }

    Process {
        id: layoutQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyLayoutState(this.text)
        }
    }

    Process {
        id: layoutEvents
        running: true
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: refreshDelay.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshDelay
        interval: 150
        onTriggered: root.refresh()
    }

    Timer {
        id: eventRestartTimer
        interval: 1000
        onTriggered: layoutEvents.running = true
    }

    Component.onCompleted: root.refresh()
}
