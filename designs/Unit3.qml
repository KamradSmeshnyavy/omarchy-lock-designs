import QtQuick
import Quickshell
import Quickshell.Io

// Unit-3 (по мотивам экрана блокировки Unit-3, samyns — MIT, widgets/lockscreen.qml; облик и размеры оттуда, код
// переписан под замок Omarchy — пароль и PAM стоковые): обои под бежевой вуалью NieR с тонкой сеткой (у него — кадр
// пиксельной волны из видео); по углам служебные строки Share Tech Mono — «● SESSION LOCKED», «NODE · user@host»,
// «セッションロック中», время с секундами и датой, ядро и WM, «ARCH LINUX · HYPRLAND»; над низом бегущая строка
// «SYSTEM SCAN · OK ▸ …»; по центру лист 380 px #d6cfb5 с рамкой чернилами и сеткой, по нему бежит красная строка:
// квадрат с ромбом и пометками NR / 2B, имя, «ユニット · アクティブ», время 46 px, дата, черта, поле «▸ ····» с шестью
// квадратиками-индикаторами, красное «AUTHENTICATION FAILED» и кнопка Login, заливающаяся чернилами при наведении.
// Лист въезжает сверху, с него сходит шторка; при ошибке — трясётся.
DesignBase {
  id: root
  field: pw

  readonly property color paper: "#d6cfb5"
  readonly property color ink: "#463f2e"
  readonly property color soft: "#7a7358"
  readonly property color red: "#6e2a2a"
  readonly property string nier: Qt.fontFamilies().indexOf("Share Tech Mono") !== -1 ? "Share Tech Mono" : root.font
  readonly property real s: Math.min(1.4, height / 1080)

  property string host: ""
  property string kernel: ""
  Process {
    running: true
    command: ["sh", "-c", "uname -n; uname -r"]
    stdout: StdioCollector { onStreamFinished: { var l = text.trim().split("\n"); root.host = l[0] || ""; root.kernel = (l[1] || "").split("-")[0] } }
  }

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  Rectangle { anchors.fill: parent; color: root.paper; opacity: 0.82 }
  Repeater { model: Math.ceil(root.width / 40); Rectangle { x: index * 40; width: 1; height: root.height; color: Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.06) } }
  Repeater { model: Math.ceil(root.height / 40); Rectangle { y: index * 40; width: root.width; height: 1; color: Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.06) } }

  component Mono: Text { font.family: root.nier; font.pixelSize: 9 * root.s; font.letterSpacing: 2 * root.s; color: root.ink }

  property real ui: 0
  NumberAnimation on ui { from: 0; to: 1; duration: 400; running: true }

  // углы
  Column {
    x: 30 * root.s; y: 28 * root.s; spacing: 2 * root.s; opacity: root.ui
    Row {
      spacing: 5 * root.s
      Rectangle {
        width: 5 * root.s; height: width; radius: width / 2; color: root.red
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity { running: !root.reduceMotion; loops: Animation.Infinite
          NumberAnimation { to: 0.3; duration: 900 } NumberAnimation { to: 1; duration: 900 } }
      }
      Mono { text: "SESSION LOCKED" }
    }
    Mono { text: "NODE · " + root.userName + "@" + (root.host || "arch") }
    Text { text: "セッションロック中"; font.pixelSize: 8 * root.s; color: root.ink; opacity: 0.7 }
  }
  Column {
    anchors { right: parent.right; rightMargin: 30 * root.s; top: parent.top; topMargin: 28 * root.s }
    spacing: 2 * root.s; opacity: root.ui
    Mono { anchors.right: parent.right; text: Qt.formatTime(root.now, root.clock24 ? "HH:mm:ss" : "hh:mm:ss AP") }
    Mono { anchors.right: parent.right; visible: root.showDate; text: Qt.formatDate(root.now, "yyyy.MM.dd · ddd").toUpperCase() }
  }
  Column {
    anchors { left: parent.left; leftMargin: 30 * root.s; bottom: parent.bottom; bottomMargin: 28 * root.s }
    spacing: 2 * root.s; opacity: root.ui
    Mono { text: "KERNEL " + (root.kernel || "—") }
    Mono { text: "WM · hyprland" }
  }
  Mono {
    anchors { right: parent.right; rightMargin: 30 * root.s; bottom: parent.bottom; bottomMargin: 28 * root.s }
    opacity: root.ui
    text: "ARCH LINUX · OMARCHY"
  }

  // бегущая строка
  Item {
    anchors { bottom: parent.bottom; bottomMargin: 65 * root.s; left: parent.left; right: parent.right }
    height: 18 * root.s; clip: true; opacity: root.ui
    Text {
      id: tick
      y: 2
      text: "SYSTEM SCAN · OK ▸ MEMORY INTEGRITY · VERIFIED ▸ SESSION LOCKED · SECURE ▸ NETWORK UPLINK · STABLE ▸ THERMAL · NOMINAL ▸ AUTH DAEMON · LISTENING ▸ "
      font.family: root.nier; font.pixelSize: 8 * root.s; font.letterSpacing: 3 * root.s; color: root.ink
      NumberAnimation on x { from: root.width; to: -tick.implicitWidth; duration: 55000; loops: Animation.Infinite; running: !root.reduceMotion }
    }
  }

  // лист
  Item {
    id: panel
    width: 380 * root.s
    height: sheet.height
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    property real drop: -200
    property real shake: 0
    anchors.verticalCenterOffset: drop * root.s
    anchors.horizontalCenterOffset: shake * root.s
    opacity: 0
    Component.onCompleted: reveal.start()
    SequentialAnimation {
      id: reveal
      ParallelAnimation {
        NumberAnimation { target: panel; property: "drop"; from: -200; to: 0; duration: 580; easing.type: Easing.OutExpo }
        NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 320 }
      }
      NumberAnimation { target: curtainScale; property: "yScale"; to: 0; duration: 460; easing.type: Easing.OutExpo }
    }
    SequentialAnimation {
      id: shakeAnim
      NumberAnimation { target: panel; property: "shake"; from: 0; to: -10; duration: 55 }
      NumberAnimation { target: panel; property: "shake"; to: 10; duration: 75 }
      NumberAnimation { target: panel; property: "shake"; to: -7; duration: 65 }
      NumberAnimation { target: panel; property: "shake"; to: 7; duration: 65 }
      NumberAnimation { target: panel; property: "shake"; to: 0; duration: 55 }
    }
    Connections {
      target: root
      function onFailedAttemptsChanged() { if (root.failedAttempts > 0) shakeAnim.restart() }
    }

    Rectangle {
      id: sheet
      width: parent.width
      height: col.implicitHeight + 72 * root.s
      color: root.paper
      border.color: root.ink; border.width: 1
      clip: true
      Repeater { model: 20; Rectangle { x: index * 20 * root.s; width: 1; height: sheet.height; color: Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.06) } }
      Repeater { model: Math.ceil(sheet.height / (20 * root.s)); Rectangle { y: index * 20 * root.s; width: sheet.width; height: 1; color: Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.06) } }
      Rectangle {
        width: parent.width; height: 1; z: 20
        gradient: Gradient { orientation: Gradient.Horizontal
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 0.5; color: root.red }
          GradientStop { position: 1; color: "transparent" } }
        SequentialAnimation on y {
          running: !root.reduceMotion; loops: Animation.Infinite
          NumberAnimation { from: 0; to: sheet.height; duration: 3500 }
          PauseAnimation { duration: 600 }
        }
      }
      Rectangle { anchors.fill: parent; color: "#c8b89a"; z: 50; transform: Scale { id: curtainScale; yScale: 1 } }

      Column {
        id: col
        width: 308 * root.s
        anchors { top: parent.top; topMargin: 36 * root.s; horizontalCenter: parent.horizontalCenter }
        Item {
          width: parent.width; height: 90 * root.s
          Rectangle {
            width: 76 * root.s; height: width
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"; border.color: root.ink; border.width: 1
            Rectangle { width: 52 * root.s; height: width; color: root.ink; anchors.centerIn: parent; rotation: 45 }
            Text { text: "NR"; font.family: root.nier; font.pixelSize: 7 * root.s; color: root.soft; opacity: 0.5; anchors { top: parent.top; left: parent.left; margins: 3 } }
            Text { text: "2B"; font.family: root.nier; font.pixelSize: 7 * root.s; color: root.soft; opacity: 0.5; anchors { bottom: parent.bottom; right: parent.right; margins: 3 } }
          }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.userName.toUpperCase(); font.family: root.nier; font.pixelSize: 13 * root.s; font.letterSpacing: 3 * root.s; color: root.ink }
        Item { width: 1; height: 4 * root.s }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ユニット · アクティブ"; font.pixelSize: 8 * root.s; color: root.soft }
        Item { width: 1; height: 20 * root.s }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, root.clock24 ? "HH:mm" : "hh:mm"); font.family: root.nier; font.pixelSize: 46 * root.s; font.letterSpacing: 2 * root.s; color: root.ink }
        Item { width: 1; height: 6 * root.s }
        Text { anchors.horizontalCenter: parent.horizontalCenter; visible: root.showDate; text: Qt.formatDate(root.now, "dddd · d MMMM yyyy").toUpperCase(); font.family: root.nier; font.pixelSize: 9 * root.s; font.letterSpacing: 3 * root.s; color: root.soft }
        Item { width: 1; height: 22 * root.s }
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.22) }
        Item { width: 1; height: 22 * root.s }
        // поле пароля
        Item {
          width: parent.width; height: 40 * root.s
          Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: root.passwordText.length > 0 || root.inputEnabled ? root.ink : Qt.rgba(70 / 255, 63 / 255, 46 / 255, 0.22) }
          Text { x: 10 * root.s; anchors.verticalCenter: parent.verticalCenter; text: "▸"; font.pixelSize: 10 * root.s; color: root.red }
          PasswordField {
            id: pw
            host: root
            anchors { fill: parent; leftMargin: 28 * root.s; rightMargin: 80 * root.s }
            bare: true
            fieldWidth: parent.width - 108 * root.s
            fieldHeight: parent.height
            fieldFontSize: 12 * root.s
            dotFontSize: 14 * root.s
            dotLetterSpacing: 2 * root.s
            textAlignment: TextInput.AlignLeft
            fontFamily: root.nier
            textColor: root.ink
            placeholderColor: Qt.rgba(122 / 255, 115 / 255, 88 / 255, 0.5)
            placeholderText: root.authenticatingPassword ? "…" : "password..."
          }
          Row {
            anchors { right: parent.right; rightMargin: 12 * root.s; verticalCenter: parent.verticalCenter }
            spacing: 4 * root.s
            Repeater {
              model: 6
              Rectangle {
                width: 6 * root.s; height: width; color: "transparent"; border.color: root.soft; border.width: 1
                Rectangle { anchors.fill: parent; visible: index < root.passwordText.length; color: root.ink }
              }
            }
          }
        }
        Item { width: 1; height: 10 * root.s }
        Text {
          visible: root.failureMessage.length > 0
          anchors.horizontalCenter: parent.horizontalCenter
          text: "AUTHENTICATION FAILED"
          font.family: root.nier; font.pixelSize: 8 * root.s; font.letterSpacing: 2 * root.s; color: root.red
        }
        Item { width: 1; height: root.failureMessage.length > 0 ? 10 * root.s : 0 }
        // кнопка Login
        Item {
          width: parent.width; height: 36 * root.s
          Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.ink; border.width: 1 }
          Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: lh.hovered ? parent.width : 0; color: root.ink; Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutQuart } } }
          Text { anchors.centerIn: parent; text: "Login"; font.family: root.nier; font.pixelSize: 10 * root.s; font.letterSpacing: 3 * root.s; color: lh.hovered ? root.paper : root.ink; Behavior on color { ColorAnimation { duration: 200 } } }
          HoverHandler { id: lh; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: if (root.passwordText.length > 0 && !root.authenticatingPassword) root.submitPassword(root.passwordText) }
        }
      }
    }
  }
}
