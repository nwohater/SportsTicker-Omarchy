import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.nwohater.sportsticker"
  manageIpc: false

  readonly property string scriptPath:
    Qt.resolvedUrl("sports-fetch").toString().replace(/^file:\/\//, "")
  readonly property string configDir: Quickshell.env("HOME") + "/.config/sports-ticker"

  readonly property var allLeagues: [
    { value: "football/nfl", label: "NFL" },
    { value: "football/college-football", label: "College Football" },
    { value: "basketball/nba", label: "NBA" },
    { value: "basketball/wnba", label: "WNBA" },
    { value: "basketball/mens-college-basketball", label: "College Basketball (M)" },
    { value: "baseball/mlb", label: "MLB" },
    { value: "hockey/nhl", label: "NHL" },
    { value: "soccer/usa.1", label: "MLS" },
    { value: "soccer/eng.1", label: "Premier League" },
    { value: "soccer/esp.1", label: "La Liga" },
    { value: "soccer/ger.1", label: "Bundesliga" },
    { value: "soccer/ita.1", label: "Serie A" },
    { value: "soccer/uefa.champions", label: "Champions League" }
  ]

  // User settings, persisted to configDir/settings.json.
  property var leagues: ["football/nfl", "basketball/nba", "baseball/mlb", "hockey/nhl"]
  property bool todayOnly: false
  property int seconds: 6

  property var games: []
  property int index: 0
  readonly property bool anyLive: games.some(function(g) { return g.state === "in" })
  readonly property var current: games.length > 0 ? games[index % games.length] : null

  function loadSettings(text) {
    try {
      var s = JSON.parse(text)
      if (Array.isArray(s.leagues)) leagues = s.leagues
      if (typeof s.todayOnly === "boolean") todayOnly = s.todayOnly
      var n = Math.round(Number(s.seconds))
      if (n >= 2 && n <= 120) seconds = n
    } catch (e) {}
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({ leagues: leagues, todayOnly: todayOnly, seconds: seconds }, null, 2) + "\n")
  }

  function toggleLeague(value) {
    var next = leagues.filter(function(v) { return v !== value })
    if (next.length === leagues.length) next.push(value)
    leagues = next
    saveSettings()
  }

  function refresh() {
    if (leagues.length === 0) { games = []; return }
    if (fetchProc.running) { refetch = true; return }
    var cmd = ["python3", root.scriptPath]
    if (todayOnly) cmd.push("--today")
    fetchProc.command = cmd.concat(leagues)
    fetchProc.running = true
  }
  property bool refetch: false

  function next() {
    if (games.length > 0) index = (index + 1) % games.length
    flip.restart()
  }

  function open() {
    controller.show()
    win.visible = true
    Qt.callLater(function() { content.forceActiveFocus() })
  }
  function close() {
    controller.hide()
    win.visible = false
  }

  onLeaguesChanged: Qt.callLater(refresh)
  onTodayOnlyChanged: Qt.callLater(refresh)
  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", configDir])

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    id: settingsFile
    path: root.configDir + "/settings.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadSettings(text())
  }

  Process {
    id: fetchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.games = JSON.parse(text || "[]")
          if (root.index >= root.games.length) root.index = 0
        } catch (e) {}
        if (root.refetch) { root.refetch = false; Qt.callLater(root.refresh) }
      }
    }
  }

  Timer {
    interval: root.anyLive ? 30000 : 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: flip
    interval: root.seconds * 1000
    running: root.games.length > 1
    repeat: true
    onTriggered: root.index = (root.index + 1) % root.games.length
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.leagues.length === 0 ? "No sports selected"
        : root.current ? (root.current.state === "in" ? "● " : "") + root.current.text : "No games"
    horizontalMargin: 6
    useActiveColor: false
    tooltipText: root.current
        ? root.current.tooltip + "\n" + root.games.length + " games · click for settings · right-click for next"
        : "Click for settings"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.next()
      else if (b === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  FloatingWindow {
    id: win
    title: "Sports Ticker"
    visible: false
    color: Color.background
    implicitWidth: 520
    implicitHeight: Math.ceil(titleBar.height + content.implicitHeight + 36)
    minimumSize: Qt.size(520, implicitHeight)
    maximumSize: Qt.size(520, implicitHeight)
    onClosed: root.close()

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.color: Color.accent
      border.width: 1
    }

    Rectangle {
      id: titleBar
      width: parent.width
      height: 34
      color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.05)
      Text {
        anchors.left: parent.left; anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "SPORTS TICKER · drag to move"
        color: Color.foreground; font.family: "monospace"; font.pixelSize: 11
      }
      MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 42
        cursorShape: Qt.SizeAllCursor
        onPressed: if (titleBar.Window.window) titleBar.Window.window.startSystemMove()
      }
      Text {
        anchors.right: parent.right; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "×"
        color: Color.foreground; font.pixelSize: 18
        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.close() }
      }
    }

    Column {
      id: content
      x: 18
      y: titleBar.height + 18
      width: parent.width - 36
      spacing: 14
      focus: true
      Keys.onEscapePressed: root.close()

      Text {
        text: "SPORTS"
        color: Color.foreground; opacity: 0.6
        font.family: "monospace"; font.pixelSize: 11; font.bold: true
      }

      Grid {
        width: parent.width
        columns: 2
        spacing: 8
        Repeater {
          model: root.allLeagues
          Toggle {
            required property var modelData
            width: (content.width - 8) / 2
            label: modelData.label
            checked: root.leagues.indexOf(modelData.value) >= 0
            onClicked: root.toggleLeague(modelData.value)
          }
        }
      }

      Toggle {
        width: parent.width
        label: "Today's games only"
        description: "Off shows yesterday through tomorrow. Live games always show."
        checked: root.todayOnly
        onClicked: { root.todayOnly = !root.todayOnly; root.saveSettings() }
      }

      NumberField {
        label: "Seconds per game"
        from: 2
        to: 120
        value: root.seconds
        onModified: { root.seconds = value; root.saveSettings() }
      }
    }
  }
}
