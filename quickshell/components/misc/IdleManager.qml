import QtQuick
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: idleManager

    // Configuration properties
    property int dimTimeout: 150               // 2.5 minutes
    property int keyboardBacklightTimeout: 150 // 2.5 minutes
    property int lockTimeout: 300              // 5 minutes
    property int monitorOffTimeout: 330        // 5.5 minutes
    property int suspendTimeout: 1800          // 30 minutes

    property int dimBrightness: 10

    property bool enableDim: true
    property bool enableKeyboardBacklight: true
    property bool enableLock: true
    property bool enableMonitorOff: true
    property bool enableSuspend: true

    // Lock object reference
    required property var lockObject

    // Internal state
    property bool wasDimmed: false
    property bool wasKeyboardOff: false
    property bool monitorsOff: false

    // Processes
    Process {
        id: brightnessDimProcess
        running: false
    }
    Process {
        id: brightnessRestoreProcess
        running: false
    }
    Process {
        id: kbdOffProcess
        running: false
    }
    Process {
        id: kbdOnProcess
        running: false
    }
    Process {
        id: monitorsOffProcess
        running: false
    }
    Process {
        id: monitorsOnProcess
        running: false
    }
    Process {
        id: suspendProcess
        running: false
    }

    // Brightness dimming
    IdleMonitor {
        id: dimMonitor
        timeout: idleManager.dimTimeout
        respectInhibitors: true
        enabled: idleManager.enableDim

        onIsIdleChanged: {
            if (isIdle && !idleManager.wasDimmed) {
                idleManager.wasDimmed = true;
                brightnessDimProcess.command = ["brightnessctl", "-s", "set", idleManager.dimBrightness.toString() + "%"];
                brightnessDimProcess.running = true;
            } else if (!isIdle && idleManager.wasDimmed) {
                idleManager.wasDimmed = false;
                brightnessRestoreProcess.command = ["brightnessctl", "-r"];
                brightnessRestoreProcess.running = true;
            }
        }
    }

    // Keyboard backlight
    IdleMonitor {
        id: kbdBacklightMonitor
        timeout: idleManager.keyboardBacklightTimeout
        respectInhibitors: true
        enabled: idleManager.enableKeyboardBacklight

        onIsIdleChanged: {
            if (isIdle && !idleManager.wasKeyboardOff) {
                idleManager.wasKeyboardOff = true;
                kbdOffProcess.command = ["brightnessctl", "-sd", "rgb:kbd_backlight", "set", "0"];
                kbdOffProcess.running = true;
            } else if (!isIdle && idleManager.wasKeyboardOff) {
                idleManager.wasKeyboardOff = false;
                kbdOnProcess.command = ["brightnessctl", "-rd", "rgb:kbd_backlight"];
                kbdOnProcess.running = true;
            }
        }
    }

    // Lock screen
    IdleMonitor {
        id: lockMonitor
        timeout: idleManager.lockTimeout
        respectInhibitors: true
        enabled: idleManager.enableLock

        onIsIdleChanged: {
            if (isIdle && !idleManager.lockObject.locked) {
                idleManager.lockObject.locked = true;
            }
        }
    }

    // Monitor power off
    IdleMonitor {
        id: dpmsMonitor
        timeout: idleManager.monitorOffTimeout
        respectInhibitors: true
        enabled: idleManager.enableMonitorOff

        onIsIdleChanged: {
            if (isIdle && !idleManager.monitorsOff) {
                idleManager.monitorsOff = true;
                monitorsOffProcess.command = ["niri", "msg", "action", "power-off-monitors"];
                monitorsOffProcess.running = true;
            } else if (!isIdle && idleManager.monitorsOff) {
                idleManager.monitorsOff = false;
                monitorsOnProcess.command = ["niri", "msg", "action", "power-on-monitors"];
                monitorsOnProcess.running = true;
            }
        }
    }

    // Suspend
    IdleMonitor {
        id: suspendMonitor
        timeout: idleManager.suspendTimeout
        respectInhibitors: true
        enabled: idleManager.enableSuspend

        onIsIdleChanged: {
            if (isIdle) {
                suspendProcess.command = ["systemctl", "suspend"];
                suspendProcess.running = true;
            }
        }
    }

    function resetStates() {
        wasDimmed = false;
        wasKeyboardOff = false;
        monitorsOff = false;
    }
}
