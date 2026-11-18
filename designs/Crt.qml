import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons as Commons

// Retro CRT (по мотивам экрана блокировки стиля Retro из elifouts/Dotfiles, GPL-3.0 — его shared/LockFaceShared.qml с
// темой Retro; облик — retro/lock-default.jpg; пароль и PAM — стоковые Omarchy). Чёрный экран трубки: слева вверху
// «HELLO, USER», по центру крупные часы Terminess цветом трубки с секундами мелко справа внизу, под ними «SUN · 15 NOV»,
// ниже — квадрат с замком; набранный пароль — точки в рамке, при ошибке — «ACCESS DENIED» и тряска. Справа вверху —
// три квадрата: сон / перезагрузка / выключение; справа внизу — карточка «NOW PLAYING» с обложкой, шкалой и ⏯.
// Включается как трубка (черта → раскрытие по вертикали).
DesignBase {
  id: root
  field: pw

  readonly property string term: Qt.fontFamilies().indexOf("Terminess Nerd Font Mono") !== -1 ? "Terminess Nerd Font Mono" : root.font
  readonly property real s: Math.min(1.5, height / 1080)
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }
  readonly property color line: a(root.accent, 0.55)

  Rectangle { anchors.fill: parent; color: root.bg }

  property real t: 0
  NumberAnimation on t { from: 0; to: 1; duration: root.reduceMotion ? 0 : 320; easing.type: Easing.OutCubic; running: true }
  readonly property real ys: Math.max(0.006, Math.min(1, (t - 0.25) / 0.75))

  Item {
    anchors.fill: parent
    opacity: root.t > 0.25 ? 1 : 0
    transform: Scale { origin.x: root.width / 2; origin.y: root.height / 2; yScale: root.ys }

    Text {
      x: 66 * root.s; y: 54 * root.s
      text: root.greeting.toUpperCase()
      font.family: root.term; font.pixelSize: 22 * root.s; font.letterSpacing: 1.5 * root.s
      color: root.accent
    }

    // сон / перезагрузка / выключение
    Row {
      anchors.right: parent.right; anchors.rightMargin: 66 * root.s
      y: 52 * root.s
      spacing: 8 * root.s
      Repeater {
        model: [["󰒲", ["systemctl", "suspend"]], ["󰜉", ["omarchy-system", "reboot"]], ["󰐥", ["omarchy-system", "shutdown"]]]
        Rectangle {
          required property var modelData
          width: 46 * root.s; height: 46 * root.s
          color: pa.containsMouse ? root.a(root.accent, 0.18) : "transparent"
          border.width: 1; border.color: root.line
          Text { anchors.centerIn: parent; text: parent.modelData[0]; font.family: root.term; font.pixelSize: 14 * root.s; color: root.accent }
          MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; enabled: !root.preview; onClicked: Quickshell.execDetached(parent.modelData[1]) }
        }
      }
    }

    Column {
      id: face
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -40 * root.s
      anchors.horizontalCenterOffset: shake * root.s
      property real shake: 0
      spacing: 0

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
          id: big
          text: Qt.formatTime(root.now, root.clock24 ? "HH:mm" : "hh:mm")
          font.family: root.term; font.pixelSize: 150 * root.s; font.bold: true
          color: root.accent
        }
        Text {
          anchors.baseline: big.baseline
          text: Qt.formatTime(root.now, "ss")
          font.family: root.term; font.pixelSize: 40 * root.s; font.bold: true
          color: root.accent
        }
      }
      Text {
        visible: root.showDate
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.now, "ddd").toUpperCase() + "   ·   " + Qt.formatDate(root.now, "dd MMM").toUpperCase()
        font.family: root.term; font.pixelSize: 24 * root.s; font.letterSpacing: 1.5 * root.s
        color: root.a(root.accent, 0.8)
      }
      Item { width: 1; height: 70 * root.s }
      Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.passwordText.length > 0 || root.failureMessage.length > 0 ? 300 * root.s : 64 * root.s
        height: 64 * root.s
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        color: "transparent"
        border.width: 1
        border.color: root.failureMessage.length > 0 ? Commons.Color.urgent : root.line
        Text {
          visible: root.passwordText.length === 0
          anchors.centerIn: parent
          text: root.authenticatingPassword ? "…" : "󰌾"
          font.family: root.term; font.pixelSize: 18 * root.s
          color: root.accent
        }
        PasswordField {
          id: pw
          host: root
          opacity: root.passwordText.length > 0 ? 1 : 0
          anchors { fill: parent; leftMargin: 14 * root.s; rightMargin: 14 * root.s }
          bare: true
          fieldWidth: parent.width - 28 * root.s
          fieldHeight: parent.height
          fieldFontSize: 16 * root.s
          dotFontSize: 18 * root.s
          dotLetterSpacing: 4 * root.s
          textAlignment: TextInput.AlignHCenter
          fontFamily: root.term
          textColor: root.accent
          placeholderColor: root.a(root.fg, 0.4)
          placeholderText: ""
        }
      }
      Item { width: 1; height: 12 * root.s }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.failureMessage.length > 0 ? "ACCESS DENIED" : ""
        font.family: root.term; font.pixelSize: 14 * root.s; font.letterSpacing: 1.5 * root.s
        color: Commons.Color.urgent
      }
    }

    // настройки слева внизу — как у него, просто знак
    Rectangle {
      x: 66 * root.s; y: parent.height - height - 54 * root.s
      width: 46 * root.s; height: 46 * root.s
      color: "transparent"; border.width: 1; border.color: root.line
      Text { anchors.centerIn: parent; text: "󰒓"; font.family: root.term; font.pixelSize: 14 * root.s; color: root.accent }
    }

    // сейчас играет
    Rectangle {
      id: media
      readonly property var player: {
        var l = Mpris.players.values
        for (var i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return l.length ? l[0] : null
      }
      visible: !!player && !!player.trackTitle
      anchors.right: parent.right; anchors.rightMargin: 66 * root.s
      y: parent.height - height - 54 * root.s
      width: 460 * root.s; height: 180 * root.s
      color: "transparent"; border.width: 1; border.color: root.line
      Rectangle {
        id: art
        x: 20 * root.s; anchors.verticalCenter: parent.verticalCenter
        width: 140 * root.s; height: width
        color: root.a(root.accent, 0.18)
        Image { anchors.fill: parent; source: media.player && media.player.trackArtUrl ? media.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 280 }
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: root.line }
      }
      Column {
        x: art.x + art.width + 22 * root.s; y: 22 * root.s
        width: media.width - x - 22 * root.s
        spacing: 6 * root.s
        Text { text: "NOW PLAYING"; font.family: root.term; font.pixelSize: 11 * root.s; font.letterSpacing: 1.5 * root.s; color: root.a(root.fg, 0.5) }
        Text { width: parent.width; elide: Text.ElideRight; text: media.player ? String(media.player.trackTitle || "").toUpperCase() : ""; font.family: root.term; font.pixelSize: 17 * root.s; font.letterSpacing: 1.5 * root.s; color: root.accent }
        Text { width: parent.width; elide: Text.ElideRight; text: media.player ? String(media.player.trackArtist || "").toUpperCase() : ""; font.family: root.term; font.pixelSize: 13 * root.s; font.letterSpacing: 1.5 * root.s; color: root.a(root.accent, 0.6) }
        Item { width: 1; height: 8 * root.s }
        Rectangle {
          width: parent.width; height: 3 * root.s
          color: root.a(root.accent, 0.18)
          Rectangle { height: parent.height; color: root.accent; width: media.player && media.player.length > 0 ? parent.width * Math.min(1, media.player.position / media.player.length) : 0 }
        }
        Item {
          width: parent.width; height: 40 * root.s
          Rectangle {
            anchors.centerIn: parent
            width: 38 * root.s; height: width; radius: width / 2
            color: root.accent
            Text { anchors.centerIn: parent; text: media.player && media.player.isPlaying ? "󰏤" : "󰐊"; font.family: root.term; font.pixelSize: 16 * root.s; color: root.bg }
            MouseArea { anchors.fill: parent; enabled: !root.preview; onClicked: if (media.player && media.player.canTogglePlaying) media.player.togglePlaying() }
          }
        }
      }
    }
  }

  // черта включения трубки
  Rectangle {
    visible: root.t < 0.999
    anchors.centerIn: parent
    width: parent.width * Math.min(1, root.t * 4)
    height: Math.max(2, parent.height * root.ys)
    color: root.accent
    opacity: Math.max(0, 1 - root.ys) * 0.9
  }

  SequentialAnimation {
    id: shakeAnim
    NumberAnimation { target: face; property: "shake"; from: 0; to: -10; duration: 55 }
    NumberAnimation { target: face; property: "shake"; to: 10; duration: 75 }
    NumberAnimation { target: face; property: "shake"; to: -6; duration: 65 }
    NumberAnimation { target: face; property: "shake"; to: 0; duration: 55 }
  }
  Connections {
    target: root
    function onFailedAttemptsChanged() { if (root.failedAttempts > 0) shakeAnim.restart() }
  }
}
