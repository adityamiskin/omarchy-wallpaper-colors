import QtQuick
import Quickshell
import Quickshell.Io

// Recolors the desktop whenever the wallpaper changes. Omarchy fires no hook for that, so this polls
// the background link with a cheap readlink and only runs the generator when it moved.
Item {
  id: root

  property var shell: null

  readonly property string bin: decodeURIComponent(String(Qt.resolvedUrl("bin/wallpaper-colors")).replace(/^file:\/\//, ""))
  property string lastBackground: ""
  property bool pending: false

  function sync() {
    if (syncProc.running) {
      root.pending = true
      return
    }
    syncProc.running = true
  }

  Process {
    id: syncProc
    command: [root.bin, "sync"]
    onExited: {
      if (!root.pending) return
      root.pending = false
      root.sync()
    }
  }

  Process {
    id: readlinkProc
    command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/omarchy/current/background"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var background = String(text || "").trim()
        if (background === "" || background === root.lastBackground) return
        root.lastBackground = background
        root.sync()
      }
    }
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: if (!readlinkProc.running) readlinkProc.running = true
  }
}
