//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "components/bar"
import "components/dashboard"
import "components/notifications"
import "components/misc"
import "components/powermenu"
import "components/polkit"
import "lockscreen"

ShellRoot {
    id: root

    property var notificationServer: NotificationServer {
        id: globalNotificationServer

        actionsSupported: true
        persistenceSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
    }

    LockManager {
        id: lockManager
    }

    IpcHandler {
        target: "lockscreen"
        function lockScreen(): void {
            lockManager.lock();
        }
    }

    IdleManager {
        id: idleManager
        lockObject: lockManager
    }

    PolkitAgent {
        id: polkitAgent
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Wallpaper {
                property var modelData
                screen: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                property var modelData
                Bar {
                    id: bar
                    screen: modelData
                }
                Dashboard {
                    screen: modelData
                    anchorWindow: bar
                }
                NotificationCenter {
                    screen: modelData
                    anchorWindow: bar
                    notificationServer: root.notificationServer
                }
            }
        }
    }

    Powermenu {}
}
