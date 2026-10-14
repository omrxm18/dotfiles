pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool showing: false
    property string query: ""

    function toggle() { query = ""; showing = !showing }

    IpcHandler {
        target: "appdrawer"
        function toggle(): void { root.toggle() }
    }

    // sort once, filter per keystroke
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = query.toLowerCase()
        return q === "" ? allApps : allApps.filter(e => e.name.toLowerCase().includes(q))
    }

    function iconFor(name) {
        if (!name) return Quickshell.iconPath("application-x-executable")
        if (name.startsWith("/")) return "file://" + name
        const p = Quickshell.iconPath(name, true)      // true = return "" if not found
        return p !== "" ? p : Quickshell.iconPath("application-x-executable")
    }

    function launch(entry) {
        entry.execute()
        root.showing = false
    }

    LazyLoader {
        active: root.showing

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "appdrawer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // click outside the drawer to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.showing = false
            }

            Rectangle {
                id: drawer
                width: 520; height: 480
                anchors.centerIn: parent
                radius: 20
                color: Theme.bg

                MouseArea { anchors.fill: parent }   // swallow clicks

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // search box
                    Rectangle {
                        width: parent.width; height: 36; radius: 10
                        color: Theme.alpha(Theme.text, 0.08)

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 13
                            focus: true
                            Component.onCompleted: forceActiveFocus()
                            onTextChanged: root.query = text
                            onAccepted: if (root.results.length > 0) root.launch(root.results[0])
                            Keys.onEscapePressed: root.showing = false
                        }
                    }

                    GridView {
                        width: parent.width
                        height: parent.height - 48
                        cellWidth: width / 5
                        cellHeight: 90
                        clip: true
                        cacheBuffer: 400
                        reuseItems: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.results

                        delegate: Item {
                            id: cell
                            required property var modelData
                            width: GridView.view.cellWidth
                            height: GridView.view.cellHeight

                            Rectangle {
                                visible: area.containsMouse           // only drawn while hovered
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 12
                                color: Theme.alpha(Theme.text, 0.1)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    id: img
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 40; height: 40
                                    sourceSize: Qt.size(48, 48)
                                    asynchronous: true
                                    cache: true
                                    source: root.iconFor(cell.modelData.icon)
                                    // fall back if the file exists but fails to decode
                                    onStatusChanged: if (status === Image.Error)
                                        source = Quickshell.iconPath("application-x-executable")
                                }
                                Text {
                                    width: cell.width - 12
                                    text: cell.modelData.name
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 10
                                    color: Theme.text
                                }
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(cell.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}