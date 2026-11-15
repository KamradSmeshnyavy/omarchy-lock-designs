import QtQuick
import Quickshell
import Quickshell.Io

// yami (по мотивам экрана входа yami, Trendorin/yami, MIT; код свой): обои темы без размытия, по центру крупное время
// пиксельным Tiny5 с жёсткой тенью, дата, строка «замок · пользователь · имя», поле пароля в рамке в пиксель с блочным
// курсором, «enter — unlock»; внизу по центру sleep / reboot / power off, слева — имя хоста и раскладка в ячейках.
DesignBase {
  id: root
  field: pw

  readonly property string px: Qt.fontFamilies().indexOf("Tiny5") !== -1 ? "Tiny5" : root.font
  readonly property color panel: Qt.rgba(root.bg.r * 0.8, root.bg.g * 0.8, root.bg.b * 0.8, 0.96)
  readonly property color line: root.withAlpha(root.fg, 0.22)
  property string host_: ""
  property string realName: ""
  property string kb: ""
  Process {
    running: true
    command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap' | head -1"]
    stdout: StdioCollector { onStreamFinished: root.kb = text.trim().slice(0, 2).toUpperCase() }
  }
  FileView { path: "/proc/sys/kernel/hostname"; onLoaded: root.host_ = text().trim() }
  Process {
    running: true
    command: ["bash", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
    stdout: StdioCollector { onStreamFinished: root.realName = text.trim() }
  }

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, Math.max(0.25, root.wallpaperDim)) }

  Column {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -40
    spacing: 14

    // время с жёсткой тенью
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: timeText.implicitWidth + 6; height: timeText.implicitHeight + 6
      Text { x: 6; y: 6; text: root.time; color: Qt.rgba(0, 0, 0, 0.7); font.family: root.px; font.pixelSize: 120 }
      Text { id: timeText; text: root.time; color: root.withAlpha(root.fg, 0.92); font.family: root.px; font.pixelSize: 120 }
    }
    Text {
      visible: root.showDate
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.dateText
      color: root.withAlpha(root.fg, 0.6)
      font.family: root.px; font.pixelSize: 22
    }
    Item { width: 1; height: 6 }
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 6
      Row {
        spacing: 8
        Text { text: "󰌾"; color: root.accent; font.family: root.font; font.pixelSize: 15 }
        Text { text: root.userName; color: root.fg; font.family: root.px; font.pixelSize: 15 }
        Text { text: root.realName; color: root.withAlpha(root.fg, 0.4); font.family: root.px; font.pixelSize: 15 }
      }
      Rectangle {
        width: 400; height: 46
        color: root.panel
        border.width: 1
        border.color: root.failedAttempts > 0 || root.failureMessage.length > 0 ? root.accent : root.line
        Rectangle {
          anchors.fill: parent; anchors.margins: 5
          color: Qt.rgba(0, 0, 0, 0.35)
          border.width: 1
          border.color: root.withAlpha(root.fg, 0.45)
          PasswordField {
            id: pw
            host: root
            anchors.fill: parent
            anchors.leftMargin: 8
            bare: true
            fieldWidth: 380
            fieldHeight: 34
            fieldFontSize: 18
            dotFontSize: 16
            dotLetterSpacing: 1
            maskCharacter: "■"
            fontFamily: root.px
            textAlignment: TextInput.AlignLeft
            textColor: root.fg
            placeholderColor: root.fg
            placeholderText: root.authenticatingPassword ? "" : "▌"
          }
        }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.failureMessage.length > 0 ? root.failureMessage : root.authenticatingPassword ? "…" : "enter — unlock"
        color: root.failureMessage.length > 0 ? root.accent : root.withAlpha(root.fg, 0.4)
        font.family: root.px; font.pixelSize: 14
      }
    }
  }

  // низ: питание по центру, хост и раскладка слева
  Row {
    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
    spacing: 30
    Repeater {
      model: [["󰒲", "sleep", ["systemctl", "suspend"]], ["󰜉", "reboot", ["omarchy-system", "reboot"]], ["󰐥", "power off", ["omarchy-system", "shutdown"]]]
      Item {
        id: pw_
        required property var modelData
        width: pr.implicitWidth; height: pr.implicitHeight
        opacity: pa.containsMouse ? 1 : 0.5
        Row {
          id: pr
          spacing: 6
          Text { text: pw_.modelData[0]; color: root.fg; font.family: root.font; font.pixelSize: 15 }
          Text { text: pw_.modelData[1]; color: root.fg; font.family: root.px; font.pixelSize: 15 }
        }
        MouseArea { id: pa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: if (!root.preview) Quickshell.execDetached(pw_.modelData[2]) }
      }
    }
  }
  Row {
    anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
    spacing: 8
    Repeater {
      model: [["󰍹", root.host_ || "omarchy"], ["󰌌", root.kb || "EN"]]
      Rectangle {
        required property var modelData
        width: cellRow.implicitWidth + 20; height: 32
        color: root.panel
        border.width: 1; border.color: root.line
        Row {
          id: cellRow
          anchors.centerIn: parent
          spacing: 6
          Text { text: modelData[0]; color: root.accent; font.family: root.font; font.pixelSize: 14 }
          Text { text: modelData[1]; color: root.fg; font.family: root.px; font.pixelSize: 14 }
        }
      }
    }
  }
  Text {
    anchors { left: parent.left; top: parent.top; margins: 22 }
    text: "yami"
    color: root.withAlpha(root.fg, 0.35)
    font.family: root.px; font.pixelSize: 14
  }
}
