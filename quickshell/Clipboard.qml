pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool showing: false
    property string query: ""
    property int index: 0
    property var entries: []

    readonly property int maxShown: 50
    readonly property string q: query.toLowerCase()
    readonly property var results: (q === "" ? entries : entries.filter(e => e.lpreview.includes(q)))
        .slice(0, maxShown)

    onQChanged: index = 0

    function open()   { query = ""; index = 0; entries = []; showing = true; listProc.running = true }
    function close()  { showing = false }
    function toggle() { showing ? close() : open() }

    // `cliphist list` prints "<id>\t<preview>" per line
    function parse(text) {
        return text.split("\n").filter(l => l.length > 0).map(l => {
            const i = l.indexOf("\t")
            const preview = i >= 0 ? l.slice(i + 1) : l
            return {
                raw: l,
                preview: preview,
                lpreview: preview.toLowerCase(),
                isImage: preview.startsWith("[[ binary data")
            }
        })
    }

    // make the entry the current clipboard, then close (paste yourself with Ctrl+V)
    function pick(e) {
        if (!e) return
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "sh", e.raw])
        close()
    }

    function remove(e) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", e.raw])
        entries = entries.filter(x => x.raw !== e.raw)
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"])
        entries = []
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
    }

    LazyLoader {
        active: root.showing

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "clipboard"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Rectangle {
                width: 520
                height: 420
                anchors.centerIn: parent
                radius: 20
                color: Theme.bg
                border.width: 1
                border.color: Theme.alpha(Theme.text, 0.12)

                MouseArea { anchors.fill: parent }   // swallow clicks

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // search box
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 10
                        color: Theme.alpha(Theme.text, 0.08)

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 13
                            focus: true
                            clip: true
                            Component.onCompleted: forceActiveFocus()
                            onTextChanged: root.query = text
                            onAccepted: root.pick(root.results[root.index])
                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: root.index = Math.min(root.index + 1, root.results.length - 1)
                            Keys.onUpPressed: root.index = Math.max(root.index - 1, 0)
                        }

                        Text {
                            visible: search.text === ""
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            text: "Search clipboard…"
                            color: Theme.textDim
                            font.pixelSize: 13
                        }
                    }

                    ListView {
                        id: list
                        width: parent.width
                        height: parent.height - 36 - 26 - 20
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: root.index
                        model: root.results

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.index

                            width: ListView.view.width
                            height: 34
                            radius: 10
                            color: selected || rowArea.containsMouse
                                ? Theme.alpha(Theme.text, 0.12)
                                : Theme.alpha(Theme.text, 0.04)
                            border.width: selected ? 1 : 0
                            border.color: Theme.accent

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.preview
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.pixelSize: 12
                                font.italic: row.modelData.isImage
                                color: row.modelData.isImage ? Theme.textDim : Theme.text
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: root.index = row.index
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) root.remove(row.modelData)
                                    else root.pick(row.modelData)
                                }
                            }
                        }
                    }

                    // footer
                    Item {
                        width: parent.width
                        height: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter: copy  ·  Right click: delete"
                            font.pixelSize: 10
                            color: Theme.textDim
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear all"
                            font.pixelSize: 10
                            font.bold: true
                            color: clearArea.containsMouse ? Theme.accent : Theme.textDim

                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.wipe()
                            }
                        }
                    }
                }
            }
        }
    }
}
