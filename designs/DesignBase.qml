import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// Основа дизайна экрана блокировки. Интерфейс — как у стокового LockView.qml,
// его заполняет LockHost.qml; пароль и PAM остаются в Service.qml.
//
// Дизайн — файл `DesignBase { … }`: кладёт Wallpaper, PasswordField { host: root }
// и что угодно ещё. Поле должно быть ровно одно и присвоено `field`, чтобы
// фокус возвращался в него по клику и при включении ввода.
Item {
  id: root

  // ── От Service.qml через LockHost ────────────────────────────────────
  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  // Настройки из ~/.config/omarchy/lock-design.json и флаг превью (без ввода).
  property var settings: ({})
  property bool preview: false

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  property Item field: null

  function forcePasswordFocus() { if (field && typeof field.forceFocus === "function") field.forceFocus() }

  // ── Настройки с дефолтами ────────────────────────────────────────────
  function opt(key, def) {
    var v = settings ? settings[key] : undefined
    return v === undefined || v === null ? def : v
  }
  readonly property bool clock24: opt("clock24", true) !== false
  readonly property bool showSeconds: opt("showSeconds", false) === true
  readonly property bool showDate: opt("showDate", true) !== false
  readonly property real wallpaperBlur: Number(opt("wallpaperBlur", 1))
  readonly property real wallpaperDim: Number(opt("wallpaperDim", 0))
  readonly property bool reduceMotion: opt("reduceMotion", false) === true
  readonly property string userName: Quickshell.env("USER") || ""
  readonly property string greeting: String(opt("ownerMessage", "")) || root.tr("Hello, %1").arg(userName)
  readonly property string avatarPath: String(opt("avatar", "")) || (Quickshell.env("HOME") + "/.face")

  // ── Язык ─────────────────────────────────────────────────────────────
  // "lang" в lock-design.json, иначе общий ~/.config/omarchy/customizer.json (тот же, что у
  // Customizer), иначе $LC_ALL / $LC_MESSAGES / $LANG: ru* — русский, остальное — английский.
  // Строки в дизайнах — английские, root.tr() переводит их.
  property string sharedLang: ""
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/customizer.json"
    printErrors: false
    onLoaded: {
      try { root.sharedLang = String(JSON.parse(text()).lang || "") } catch (e) { root.sharedLang = "" }
    }
    onLoadFailed: root.sharedLang = ""
  }
  readonly property string lang: {
    var l = String(opt("lang", "")) || root.sharedLang
      || Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "en"
    return /^ru/.test(l) ? "ru" : "en"
  }
  readonly property var strings: ({
    ru: {
      "Hello, %1": "Привет, %1",
      "password": "пароль",
      "[ enter password ]": "[ введите пароль ]",
      "just type": "просто печатайте",
      "Untitled": "Без названия",
      "Nothing playing": "Ничего не играет",
      "%1d ": "%1д ", "%1h ": "%1ч ", "%1m": "%1м",
      "Uptime": "Аптайм", "Memory": "Память", "Load": "Нагрузка", "Battery": "Батарея",
      "GB": "ГБ", "none": "нет"
    }
  })
  function tr(s) {
    var t = strings[root.lang]
    return t && t[s] !== undefined ? t[s] : s
  }

  // ── Палитра темы ─────────────────────────────────────────────────────
  readonly property color bg: Commons.Color.background
  readonly property color fg: Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color muted: Commons.Color.muted
  readonly property string font: Style.font.family

  // ── Время ────────────────────────────────────────────────────────────
  property date now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }
  function timeText(d) {
    var f = root.clock24 ? (root.showSeconds ? "HH:mm:ss" : "HH:mm") : (root.showSeconds ? "h:mm:ss AP" : "h:mm AP")
    return Qt.formatTime(d || root.now, f)
  }
  readonly property string time: timeText(now)
  readonly property string hours: Qt.formatTime(now, clock24 ? "HH" : "hh")
  readonly property string minutes: Qt.formatTime(now, "mm")
  readonly property string dateText: Qt.locale().toString(now, "dddd, d MMMM")

  function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // Клик и движение мыши — разбудить экран и вернуть фокус в поле.
  MouseArea {
    anchors.fill: parent
    z: -100
    hoverEnabled: true
    onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
    onPositionChanged: root.wakeRequested()
  }
  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
  Component.onCompleted: if (inputEnabled) Qt.callLater(forcePasswordFocus)
}
