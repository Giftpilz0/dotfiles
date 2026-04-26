pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool dashboardVisible: false
    property bool lockscreenVisible: false
    property bool notificationCenterVisible: false
    property bool powermenuVisible: false

    function toggleDashboard() {
        if (powermenuVisible)
            powermenuVisible = false;
        dashboardVisible = !dashboardVisible;
    }

    function togglePowermenu() {
        if (dashboardVisible)
            dashboardVisible = false;
        powermenuVisible = !powermenuVisible;
    }

    function toggleLockscreen() {
        lockscreenVisible = !lockscreenVisible;
    }
}
