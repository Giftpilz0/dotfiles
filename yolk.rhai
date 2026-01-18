private fn merge_into_home(enabled, templates) {
    #{ enabled: enabled, targets: "~", strategy: "merge", templates: templates }
}

export let eggs = #{
    dgop: #{ targets: "~/.config/dgop", enabled: true },
    DankMaterialShell: #{ targets: "~/.config/DankMaterialShell", enabled: true },
    helix: #{ targets: "~/.config/helix", enabled: true },
    kitty: #{ targets: "~/.config/kitty", enabled: true },
    matugen: #{ targets: "~/.config/matugen", enabled: true },
    niri: #{ targets: "~/.config/niri", enabled: true },
    quickshell: #{ targets: "~/.config/quickshell", enabled: true },
    vim: #{ targets: "~/.config/vim", enabled: true },
    wofi: #{ targets: "~/.config/wofi", enabled: true },
    "xdg-desktop-portal": #{ targets: "~/.config/xdg-desktop-portal", enabled: true },
    zed: #{ targets: "~/.var/app/dev.zed.Zed/config/zed", enabled: true },

    gtk: merge_into_home(true, []),
    inputrc: merge_into_home(true, []),
    libreoffice: merge_into_home(true, []),
    bashrc: merge_into_home(true, []),
    systemd: merge_into_home(true, []),

    dconf: #{ targets: "/", strategy: "merge", unsafe_shell_hooks: #{ post_deploy: "post_deploy/dconf_update.sh" }},
};
