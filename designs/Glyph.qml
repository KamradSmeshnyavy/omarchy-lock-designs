import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "glyph"

// Glyph — экран блокировки из glyph-rice (lock/LockSurface.qml, GPL-3.0) на DesignBase: пароль и PAM — стоковые
// (Service.qml), здесь только вид. Часы Doto на всю ширину, дата и что играет — метками, в углу раскладка и батарея.
// Внизу аватар в кольце точек, имя и поле-пилюля: введённое — белые точки, каретка красная, пока PAM думает — по
// точкам бежит волна; неверный пароль — всё красное, поле трясётся. Обои собираются из точек волной (glyph/Wall.qml)
// в виде из ~/.config/omarchy/wallpaper-look.json (тот же, что у фона и picker'а glyph).
DesignBase {
  id: root
  field: pw

  readonly property bool fail: root.failureMessage.length > 0
  readonly property bool busy: root.authenticatingPassword
  readonly property int typedCount: pw.length
  readonly property var loc: Qt.locale(root.lang === "ru" ? "ru_RU" : "en_US")
  function ntr(en, ru) { return root.lang === "ru" ? ru : en }

  property bool blink: true
  Timer { running: !root.reduceMotion; interval: 500; repeat: true; onTriggered: root.blink = !root.blink }

  // появление: t 0→1 линейно, у каждого элемента своя фаза с ease-out-quart — часы, метки, аватар (кольцо загорается
  // волной), поле вырастает из точки
  property real t: root.reduceMotion ? 1 : 0
  Behavior on t { NumberAnimation { duration: 1100 } }
  Component.onCompleted: t = 1
  function ph(a, b) { var x = Math.max(0, Math.min(1, (t - a) / (b - a))); return 1 - Math.pow(1 - x, 4) }
  property real wave: 0
  NumberAnimation on wave { running: root.busy; from: 0; to: 1; duration: 700; loops: Animation.Infinite }

  // вид обоев — общий с фоном
  property var look: ({})
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/wallpaper-look.json"
    printErrors: false
    onLoaded: { try { root.look = JSON.parse(text()) || {} } catch (e) { root.look = {} } }
    onLoadFailed: root.look = {}
  }

  // раскладка клавиатуры: две буквы активной
  property string layout: ""
  function short(name) { return String(name || "").slice(0, 2).toLowerCase() }
  Process {
    running: true
    command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap'"]
    stdout: StdioCollector { onStreamFinished: if (text.trim()) root.layout = root.short(text.trim()) }
  }
  Connections {
    target: Hyprland
    function onRawEvent(e) { if (e.name === "activelayout") root.layout = root.short(e.data.split(",").pop()) }
  }

  readonly property var bat: UPower.displayDevice
  readonly property var player: {
    var list = Mpris.players.values
    for (var i = 0; i < list.length; i++) if (list[i].isPlaying) return list[i]
    return list.length ? list[0] : null
  }

  Rectangle { anchors.fill: parent; color: GTheme.bg }

  // холст макета 1920×1080 (Stage у glyph-rice)
  readonly property real s: Math.min(width / 1920, height / 1080)
  Item {
    id: stage
    width: root.width / root.s
    height: root.height / root.s
    scale: root.s
    transformOrigin: Item.TopLeft

    Item {
      anchors.fill: parent
      opacity: root.ph(0, 0.6)
      Image {
        visible: !wall.opaque
        anchors.fill: parent
        fillMode: Image.Tile
        source: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="1.5" fill="' + GTheme.s2 + '"/></svg>')
      }
      Wall {
        id: wall
        anchors.fill: parent
        path: root.loadBackground && !/\.(mp4|m4v|mov|webm|mkv|avi)$/i.test(root.backgroundPath) ? root.backgroundPath : ""
        look: ({ "dots": 0, "mono": 1 })[String(root.look.look)] ?? 2
        pitch: Math.max(4, Math.min(32, Number(root.look.pitch) || 10))
        bright: Math.max(0.1, Math.min(1, (Number(root.look.bright) || 100) / 100)) * (1 - Math.max(0, Math.min(0.9, Number(root.opt("wallpaperDim", 0.35)))))
        origin: Qt.point(width / 2, height - 300)
      }
    }

    Lb {
      visible: root.showDate
      anchors.horizontalCenter: parent.horizontalCenter
      y: 170
      text: root.loc.toString(root.now, "dddd · d MMMM")
      px: 14
      opacity: root.ph(0.15, 0.55)
      transform: Translate { y: 16 * (1 - root.ph(0.15, 0.55)) }
    }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 230
      opacity: root.ph(0, 0.5)
      transform: Translate { y: -40 * (1 - root.ph(0, 0.5)) }
      Num { text: root.hours; font.pixelSize: 400 }
      Num { text: ":"; font.pixelSize: 400; opacity: root.blink ? 1 : 0.2 }
      Num { text: root.minutes; font.pixelSize: 400 }
    }
    Lb {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 600
      width: 900
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      opacity: root.ph(0.25, 0.65)
      transform: Translate { y: 16 * (1 - root.ph(0.25, 0.65)) }
      text: root.player && root.player.trackTitle ? root.player.trackTitle + (root.player.trackArtist ? " — " + root.player.trackArtist : "") : ""
    }

    Row {
      anchors { right: parent.right; rightMargin: 44 }
      y: 36
      spacing: 16
      opacity: root.ph(0.45, 0.85)
      Lb { anchors.verticalCenter: parent.verticalCenter; text: root.layout }
      Rectangle {
        visible: !!root.bat && root.bat.isLaptopBattery
        anchors.verticalCenter: parent.verticalCenter
        width: 27
        height: 13
        radius: 7
        color: "transparent"
        border { width: 1.5; color: GTheme.grey }
        Rectangle { x: 3; y: 3; width: (parent.width - 6) * (root.bat ? root.bat.percentage : 0); height: parent.height - 6; radius: 4; color: GTheme.fg }
      }
      Lb { visible: !!root.bat && root.bat.isLaptopBattery; anchors.verticalCenter: parent.verticalCenter; text: root.bat ? Math.round(root.bat.percentage * 100) : "" }
    }

    Column {
      anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 120 }
      spacing: 16

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 96
        height: 96
        opacity: root.ph(0.3, 0.7)
        transform: Translate { y: 24 * (1 - root.ph(0.3, 0.7)) }
        Ring { anchors.fill: parent; n: 32; f: root.t > 0.35 ? 1 : 0 }
        // аватар точками, как обложки; нет файла — градиент Art
        Art { anchors { fill: parent; margins: 18 } url: GTheme.url(root.avatarPath); step: 3 }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(root.opt("ownerMessage", "")) || root.userName
        font { family: "Space Grotesk"; pixelSize: 22 }
        color: GTheme.fg
        opacity: root.ph(0.4, 0.75)
        transform: Translate { y: 16 * (1 - root.ph(0.4, 0.75)) }
      }

      // поле: введённые — точки, после каретки — погасшие до шести
      Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: 58 + (380 - 58) * root.ph(0.5, 0.9)
        height: 58
        radius: 29
        opacity: root.ph(0.45, 0.6)
        color: GTheme.s1
        border { width: 1; color: root.fail ? GTheme.accent : GTheme.s3 }

        // невидимое стоковое поле держит фокус и ввод (Enter, Esc, Ctrl+U)
        PasswordField {
          id: pw
          host: root
          anchors.fill: parent
          fieldWidth: pill.width
          fieldHeight: pill.height
          bare: true
          opacity: 0
        }

        Row {
          anchors.centerIn: parent
          spacing: 14
          opacity: root.ph(0.75, 1)
          Repeater {
            id: typed
            model: Math.min(root.typedCount, 16)
            Rectangle {
              required property int index
              anchors.verticalCenter: parent.verticalCenter
              width: 11
              height: 11
              radius: 5.5
              color: root.fail ? GTheme.accent : GTheme.fg
              opacity: root.busy && Math.abs(root.wave * (typed.count + 2) - 1 - index) > 1.2 ? 0.3 : 1
              NumberAnimation on scale { from: 0.2; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
          }
          Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 2; height: 24; color: GTheme.accent; opacity: root.blink ? 1 : 0 }
          Repeater {
            model: Math.max(0, 6 - root.typedCount)
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 11; height: 11; radius: 5.5; color: GTheme.s3 }
          }
        }

        SequentialAnimation {
          id: shake
          loops: 2
          NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
          NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 10; duration: 80 }
          NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
        }
        Connections {
          target: root
          function onFailedAttemptsChanged() { if (root.failedAttempts > 0 && !root.reduceMotion) shake.restart() }
        }
      }
      Lb {
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.ph(0.8, 1)
        text: root.busy ? root.ntr("checking…", "проверка…")
          : root.fail ? root.ntr("wrong password · try again", "неверный пароль · ещё раз")
          : root.fingerprintConfigured ? root.ntr("enter password or touch the sensor", "пароль или отпечаток")
          : root.ntr("enter password", "введите пароль")
        color: root.fail ? GTheme.accent : GTheme.grey
      }
    }
  }
}
