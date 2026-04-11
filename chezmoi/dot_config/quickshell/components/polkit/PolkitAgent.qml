import QtQuick
import Quickshell.Services.Polkit

Item {
    id: root

    PolkitAgent {
        id: agent

        onFlowChanged: {
            if (flow && flow.message) {
                polkitDialog.visible = true;
            } else {
                polkitDialog.visible = false;
            }
        }
    }

    PolkitDialog {
        id: polkitDialog
        polkitAgent: agent
        visible: false
    }
}
