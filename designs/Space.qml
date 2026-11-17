import QtQuick
import Quickshell
import qs.Commons as Commons

// Space (по мотивам экрана блокировки стиля Space из elifouts/Dotfiles, GPL-3.0 — его shared/LockFaceShared.qml с
// Theme Space: капс, разрядка, прямые углы; облик с его скриншота space/lock.png; пароль и PAM — стоковые Omarchy):
// пейзаж обоев, притушенный к низу, по центру крупные тонкие часы с широкой разрядкой, дата капсом вразрядку,
// поле пароля 300 × 34 с рамкой акцентом и подписью PASSWORD, под ним — имя пользователя. При ошибке поле трясётся,
// рамка — цветом тревоги. Всё проступает «расшифровкой» и поднимается снизу.
DesignBase {
  id: root
  field: pw

  readonly property string mono: Qt.fontFamilies().indexOf("JetBrainsMono Nerd Font") !== -1 ? "JetBrainsMono Nerd Font" : root.font
  readonly property real s: Math.min(1.5, height / 1080)
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  // его lock: земля «притушена» — сверху легко, к низу гуще
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: root.a(root.bg, 0.35) }
      GradientStop { position: 0.6; color: root.a(root.bg, 0.45) }
      GradientStop { position: 1; color: root.a(root.bg, 0.7) }
    }
  }

  property real ui: 0
  NumberAnimation on ui { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic; running: true }

  Column {
    id: face
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: (30 + 24 * (1 - root.ui)) * root.s
    anchors.horizontalCenterOffset: shake * root.s
    property real shake: 0
    opacity: root.ui
    spacing: 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.time
      font.family: root.mono
      font.pixelSize: 128 * root.s
      font.weight: Font.Thin
      font.letterSpacing: 10 * root.s
      color: root.fg
    }
    Item { width: 1; height: 14 * root.s }
    Text {
      visible: root.showDate
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(root.now, "dddd  ·  dd MMMM").toUpperCase()
      font.family: root.mono
      font.pixelSize: 12 * root.s
      font.letterSpacing: 2.4 * root.s
      color: root.a(root.fg, 0.6)
    }
    Item { width: 1; height: 46 * root.s }
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 300 * root.s
      height: 34 * root.s
      color: root.a(root.bg, 0.35)
      border.width: 1
      border.color: root.failureMessage.length > 0 ? Commons.Color.urgent : root.a(root.accent, root.passwordText.length > 0 ? 1 : 0.75)
      PasswordField {
        id: pw
        host: root
        anchors { fill: parent; leftMargin: 14 * root.s; rightMargin: 14 * root.s }
        bare: true
        fieldWidth: parent.width - 28 * root.s
        fieldHeight: parent.height
        fieldFontSize: 12 * root.s
        dotFontSize: 14 * root.s
        dotLetterSpacing: 3 * root.s
        textAlignment: TextInput.AlignLeft
        fontFamily: root.mono
        textColor: root.fg
        placeholderColor: root.a(root.fg, 0.4)
        placeholderText: root.authenticatingPassword ? "…" : "PASSWORD"
      }
    }
    Item { width: 1; height: 12 * root.s }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.failureMessage.length > 0 ? "ACCESS DENIED" : root.userName.toUpperCase()
      font.family: root.mono
      font.pixelSize: 10 * root.s
      font.letterSpacing: 2.4 * root.s
      color: root.failureMessage.length > 0 ? Commons.Color.urgent : root.a(root.fg, 0.45)
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
