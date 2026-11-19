import QtQuick
import Quickshell
import qs.Commons as Commons

// Modern (по мотивам экрана блокировки стиля Modern из elifouts/Dotfiles, GPL-3.0 — его shared/LockFaceShared.qml с
// темой Modern; облик — v2/lock-default.png; пароль и PAM — стоковые Omarchy): обои под сильным размытием и лёгким
// затемнением, по центру курсивом «Hello, имя» (имя — акцентом), под ним тёмная скруглённая пилюля пароля, которая
// раскрывается при наборе; при ошибке — тряска и подсветка тревогой.
DesignBase {
  id: root
  field: pw

  readonly property string ui: Qt.fontFamilies().indexOf("CodeNewRoman Nerd Font Propo") !== -1 ? "CodeNewRoman Nerd Font Propo"
    : Qt.fontFamilies().indexOf("JetBrainsMono Nerd Font") !== -1 ? "JetBrainsMono Nerd Font" : root.font
  readonly property real s: Math.min(1.5, height / 1080)
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }

  Wallpaper { anchors.fill: parent; host: root; blur: 1 }
  Rectangle { anchors.fill: parent; color: root.a(root.bg, 0.25) }

  property real ui_: 0
  NumberAnimation on ui_ { from: 0; to: 1; duration: root.reduceMotion ? 0 : 700; easing.type: Easing.OutCubic; running: true }

  Column {
    id: face
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: shake * root.s
    property real shake: 0
    opacity: root.ui_
    spacing: 22 * root.s
    transform: Translate { y: (1 - root.ui_) * 20 * root.s }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      Text { text: "Hello "; font.family: root.ui; font.pixelSize: 40 * root.s; font.italic: true; color: root.a(root.fg, 0.85) }
      Text { text: root.userName; font.family: root.ui; font.pixelSize: 40 * root.s; font.italic: true; color: root.accent }
    }
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: (root.passwordText.length > 0 || root.failureMessage.length > 0 ? 300 : 110) * root.s
      height: 40 * root.s
      radius: height / 2
      Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      color: root.a(root.bg, 0.75)
      border.width: 1
      border.color: root.failureMessage.length > 0 ? Commons.Color.urgent : root.a(root.fg, 0.1)
      PasswordField {
        id: pw
        host: root
        anchors { fill: parent; leftMargin: 18 * root.s; rightMargin: 18 * root.s }
        bare: true
        fieldWidth: parent.width - 36 * root.s
        fieldHeight: parent.height
        fieldFontSize: 14 * root.s
        dotFontSize: 14 * root.s
        dotLetterSpacing: 3 * root.s
        textAlignment: TextInput.AlignHCenter
        fontFamily: root.ui
        textColor: root.fg
        placeholderColor: root.a(root.fg, 0.35)
        placeholderText: root.authenticatingPassword ? "…" : ""
      }
    }
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
