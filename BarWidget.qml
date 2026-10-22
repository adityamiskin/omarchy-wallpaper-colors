import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar button + popup listing the accents the wallpaper's source colors produce. Picking one rebuilds
// the whole palette around it.
Panel {
  id: root
  moduleName: "adityamiskin.wallpaper-colors"
  ipcTarget: "adityamiskin.wallpaper-colors"

  readonly property string bin: decodeURIComponent(String(Qt.resolvedUrl("bin/wallpaper-colors")).replace(/^file:\/\//, ""))
  readonly property color fg: root.bar ? root.bar.foreground : Commons.Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family

  property var colors: []
  property int active: 0
  property string error: ""
  property bool loading: false
  property bool applying: false
  property int cursor: 0
  property bool cursorActive: false

  // Matugen's first candidate is the default; picking another is remembered for this wallpaper.
  readonly property var rows: root.colors.map(function(color, i) {
    return { index: i, name: i === 0 ? "Default" : "Color " + (i + 1), color: color }
  })
  readonly property int activeRow: root.active

  function refresh() {
    if (sourcesProc.running) return
    root.loading = root.colors.length === 0
    root.error = ""
    sourcesProc.running = true
  }

  function pick(index) {
    if (pickProc.running) return
    root.applying = true
    root.error = ""
    pickProc.command = [root.bin, "pick", String(index)]
    pickProc.running = true
  }

  onOpenedChanged: {
    if (!opened) return
    root.cursorActive = false
    refresh()
  }

  Process {
    id: sourcesProc
    command: [root.bin, "sources"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        try {
          var result = JSON.parse(String(text || "").trim())
          root.colors = result.colors
          root.active = result.active
          root.cursor = root.activeRow
        } catch (e) {
          root.error = "Couldn't read the wallpaper's colors. Is matugen installed?"
        }
      }
    }
  }

  Process {
    id: pickProc
    onExited: function(code) {
      root.applying = false
      if (code !== 0) root.error = "Couldn't apply that color"
      root.refresh()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏘"
    tooltipText: "Wallpaper colors"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) {
          root.cursorActive = true
          return
        }
        root.cursor = (root.cursor + (dx !== 0 ? dx : dy) + root.rows.length) % root.rows.length
      }
      onActivateRequested: if (root.cursorActive && root.colors.length > 0) root.pick(root.rows[root.cursor].index)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "Accent"
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        Text {
          visible: root.loading || root.applying || root.error !== ""
          width: parent.width
          wrapMode: Text.Wrap
          textFormat: Text.PlainText
          text: root.error !== "" ? root.error : root.applying ? "Applying…" : "Reading the wallpaper…"
          color: root.error !== "" ? Commons.Color.urgent : root.fg
          opacity: root.error !== "" ? 1 : 0.6
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Repeater {
          model: root.colors.length > 0 ? root.rows : []

          Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === root.activeRow
            readonly property bool hasCursor: (root.cursorActive && root.cursor === index) || mouse.containsMouse

            width: column.width
            height: Style.space(36)
            radius: Style.cornerRadius
            color: hasCursor ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"
            border.width: current ? Math.max(1, Style.space(2)) : 0
            border.color: modelData.color || root.fg

            Rectangle {
              id: swatch
              anchors.left: parent.left
              anchors.leftMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(20)
              height: width
              radius: width / 2
              color: row.modelData.color || "transparent"
            }

            Text {
              anchors.left: swatch.right
              anchors.leftMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: row.modelData.name
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: row.current
            }

            Text {
              anchors.right: parent.right
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: row.current ? "✓" : row.modelData.color
              color: root.fg
              opacity: row.current ? 1 : 0.5
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: {
                root.cursorActive = true
                root.cursor = row.index
              }
              onClicked: root.pick(row.modelData.index)
            }
          }
        }
      }
    }
  }
}
