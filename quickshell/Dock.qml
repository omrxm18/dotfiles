pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property var pinned: []
    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/state/dock.json"

    function save(list) {
        root.pinned = list
        file.setText(JSON.stringify({ pinned: list }, null, 2))
    }

    function pin(id)    { if (id && pinned.indexOf(id) < 0) save(pinned.concat([id])) }
    function unpin(id)  { save(pinned.filter(x => x !== id)) }
    function toggle(id) { pinned.indexOf(id) >= 0 ? unpin(id) : pin(id) }

    // ---- window helpers --------------------------------------------------
    function appWindow(id) {
        return ToplevelManager.toplevels.values.find(
            t => t.appId.toLowerCase() === id.toLowerCase())
    }

    function focusOrLaunch(id) {
        const w = appWindow(id)
        if (w) w.activate()
        else DesktopEntries.heuristicLookup(id)?.execute()
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            try {
                const s = JSON.parse(file.text())
                if (Array.isArray(s.pinned))
                    root.pinned = s.pinned.filter(x => typeof x === "string")
            } catch (e) {
                console.warn("dock: could not read", root.path, e)
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                file.setText(JSON.stringify({ pinned: [] }, null, 2))
        }
    }

    IpcHandler {
        target: "dock"
        function pin(id: string): void { root.pin(id) }
        function unpin(id: string): void { root.unpin(id) }
        function toggle(id: string): void { root.toggle(id) }
        // pin whichever window is focused right now (uses its real appId)
        function pinActive(): void {
            const t = ToplevelManager.activeToplevel
            if (t) root.pin(t.appId)
        }
    }

    PanelWindow {
        anchors.bottom: true            // only bottom anchored = centered horizontally
        margins.bottom: 8
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 60
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.pinned.length > 0

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Theme.bg

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 10

                Repeater {
                    model: root.pinned

                    delegate: Item {
                        id: item
                        required property string modelData
                        // reading .values makes this re-run once the desktop entry
                        // database finishes loading (it's async at shell startup)
                        readonly property var entry: {
                            DesktopEntries.applications.values
                            return DesktopEntries.heuristicLookup(modelData)
                        }
                        readonly property bool running: root.appWindow(modelData) !== undefined

                        width: 40
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Theme.alpha(Theme.text, ma.containsMouse ? 0.12 : 0)
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            sourceSize: Qt.size(48, 48)
                            asynchronous: true
                            source: Quickshell.iconPath(
                                item.entry?.icon || "application-x-executable",
                                "application-x-executable")
                        }

                        // running indicator
                        Rectangle {
                            visible: item.running
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 6
                            height: 3
                            radius: 1.5
                            color: Theme.accent
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) root.unpin(item.modelData)
                                else root.focusOrLaunch(item.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
