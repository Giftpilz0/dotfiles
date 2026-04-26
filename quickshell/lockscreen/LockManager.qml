import QtQuick
import Quickshell.Wayland

Item {
    id: lockManager

    property alias locked: sessionLock.locked

    LockContext {
        id: lockContext
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: lockSurface
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    Connections {
        target: lockContext
        function onUnlocked() {
            sessionLock.locked = false;
        }
    }

    function lock() {
        sessionLock.locked = true;
    }
}
