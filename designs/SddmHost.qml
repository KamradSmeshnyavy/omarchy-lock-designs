import QtQuick
import Quickshell
import Quickshell.Io

// SDDM-темы как дизайн экрана блокировки (темы qylock и любые другие SDDM-темы на QML). Код свой: тема
// ждёт от SDDM объекты sddm, config, userModel, sessionModel, keyboard — здесь они объявлены свойствами
// корня, а Loader темы создан в контексте этого файла, поэтому тема видит их как глобальные имена.
//
// Пароль: sddm.login(user, password, session) → submitPassword → стоковый PAM в Service.qml (тема его
// не видит); неверный пароль (failedAttempts растёт) → sddm.loginFailed(). Успех — экран снимает сам Service.
// Темы лежат в ~/.local/share/omarchy-lock-themes/<источник>/themes/<имя>/Main.qml (scripts/bin/omarchy-lock-themes
// скачивает их и переписывает импорты Qt5 на шимы). Не загрузилась тема — LockHost покажет стоковый экран.
DesignBase {
  id: root

  // Имя темы: "qylock/nier-automata" (источник/тема) или просто "nier-automata" (источник qylock).
  property string sddmTheme: ""
  readonly property string themesRoot: Quickshell.env("HOME") + "/.local/share/omarchy-lock-themes"
  readonly property string themeDir: {
    var t = String(sddmTheme || "")
    if (t === "" || /\.\.|^\//.test(t)) return ""
    var parts = t.indexOf("/") > 0 ? t.split("/") : ["qylock", t]
    return root.themesRoot + "/" + parts[0] + "/themes/" + parts[1]
  }

  // ── То, что тема берёт у SDDM ───────────────────────────────────────
  property var config: ({})
  readonly property var sddm: sddmObj
  readonly property var userModel: users
  readonly property var sessionModel: sessions
  readonly property var keyboard: ({ capsLock: false, numLock: true, layouts: [], currentLayout: 0 })

  QtObject {
    id: sddmObj
    signal loginSucceeded()
    signal loginFailed()
    signal informationMessage(string message)
    readonly property string hostName: Quickshell.env("HOSTNAME") || "omarchy"
    readonly property bool canPowerOff: true
    readonly property bool canReboot: true
    readonly property bool canSuspend: true
    readonly property bool canHibernate: false
    readonly property bool canHybridSleep: false
    function login(user, password, session) { root.submitPassword(String(password || "")) }
    function powerOff() { Quickshell.execDetached(["omarchy-system", "shutdown"]) }
    function reboot() { Quickshell.execDetached(["omarchy-system", "reboot"]) }
    function suspend() { Quickshell.execDetached(["systemctl", "suspend"]) }
    function hibernate() { Quickshell.execDetached(["systemctl", "hibernate"]) }
    function hybridSleep() { Quickshell.execDetached(["systemctl", "hybrid-sleep"]) }
  }
  // Неверный пароль — событие темы (тряска, красное поле и т. п.).
  onFailedAttemptsChanged: if (failedAttempts > 0) sddmObj.loginFailed()

  ListModel {
    id: users
    property string lastUser: root.userName
    property int lastIndex: 0
    property int disableAvatarsThreshold: 7
    function rowCount() { return count }
    function index(row, col) { return row }
    function data(row, role) {
      var it = get(typeof row === "number" ? row : 0)
      if (!it) return ""
      if (role === Qt.UserRole + 2) return it.realName
      if (role === Qt.UserRole + 4) return it.icon
      return it.name
    }
    Component.onCompleted: append({ name: root.userName, realName: root.userName, icon: root.avatarPath, homeDir: Quickshell.env("HOME") })
  }
  ListModel {
    id: sessions
    property int lastIndex: 0
    function rowCount() { return count }
    function index(row, col) { return row }
    function data(row, role) { var it = get(typeof row === "number" ? row : 0); return it ? it.name : "" }
    Component.onCompleted: append({ name: "Hyprland", file: "hyprland.desktop" })
  }

  // theme.conf: [General] key=value → config.key; плюс методы SDDM (stringValue / boolValue / intValue).
  FileView {
    path: root.themeDir !== "" ? root.themeDir + "/theme.conf" : ""
    printErrors: false
    onLoaded: {
      var c = {}
      var lines = String(text() || "").split("\n")
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === "" || line.charAt(0) === "[" || line.charAt(0) === "#" || line.charAt(0) === ";") continue
        var eq = line.indexOf("=")
        if (eq > 0) c[line.slice(0, eq).trim()] = line.slice(eq + 1).trim().replace(/^"(.*)"$/, "$1")
      }
      if (!c.background) c.background = "bg.png"
      c.stringValue = function(k) { return c[k] !== undefined ? String(c[k]) : "" }
      c.boolValue = function(k) { return String(c[k]) === "true" }
      c.intValue = function(k) { return parseInt(c[k]) || 0 }
      c.realValue = function(k) { return parseFloat(c[k]) || 0 }
      root.config = c
    }
    onLoadFailed: root.config = { background: "bg.png" }
  }

  // Поле для LockHost: «фокус» — фокус в тему. Пока тема не загрузилась, поля нет, и через полсекунды
  // LockHost покажет сток.
  Item {
    id: focusProxy
    function forceFocus() { if (theme.item) theme.item.forceActiveFocus() }
  }
  // Аварийный выход: Ctrl+Alt+Enter — бросить тему и показать стоковое поле пароля (если у темы сломан ввод,
  // экран всё равно можно разблокировать). Поле становится null — LockHost переключается на сток.
  property bool abandoned: false
  onSddmThemeChanged: abandoned = false
  Shortcut {
    sequences: ["Ctrl+Alt+Return", "Ctrl+Alt+Enter"]
    context: Qt.WindowShortcut
    onActivated: root.abandoned = true
  }
  field: theme.status === Loader.Ready && !abandoned ? focusProxy : null

  Rectangle { anchors.fill: parent; color: "black" }
  Loader {
    id: theme
    anchors.fill: parent
    // Тема ждёт config при создании: грузим, когда theme.conf прочитан (или его нет).
    active: root.themeDir !== "" && root.config.background !== undefined
    source: active ? "file://" + root.themeDir + "/Main.qml" : ""
    focus: true
    onLoaded: Qt.callLater(function() { if (theme.item) theme.item.forceActiveFocus() })
    onStatusChanged: if (status === Loader.Error) console.warn("lock: SDDM theme failed to load: " + source)
  }
}
