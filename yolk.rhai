private fn merge_into_home(enabled, templates) {
    #{ enabled: enabled, targets: "~", strategy: "merge", templates: templates }
}

export let eggs = #{
    bin: #{ targets: "~/.local/bin", enabled: true },
    common: #{ targets: "~/.config/common", enabled: true },
    cosmic: #{ targets: "~/.config/cosmic", enabled: true },
    eww: #{ targets: "~/.config/eww", enabled: true },
    helix: #{ targets: "~/.config/helix", enabled: true },
    hypr: #{ targets: "~/.config/hypr", enabled: true },
    kitty: #{ targets: "~/.config/kitty", enabled: true },
    matugen: #{ targets: "~/.config/matugen", enabled: true },
    niri: #{ targets: "~/.config/niri", enabled: true },
    sway: #{ targets: "~/.config/sway", enabled: true },
    swaync: #{ targets: "~/.config/swaync", enabled: true },
    vim: #{ targets: "~/.config/vim", enabled: true },
    wofi: #{ targets: "~/.config/wofi", enabled: true },
    "xdg-desktop-portal": #{ targets: "~/.config/xdg-desktop-portal", enabled: true },

    gtk: merge_into_home(true, []),
    inputrc: merge_into_home(true, []),
    libreoffice: merge_into_home(true, []),
    bashrc: merge_into_home(true, []),
    systemd: merge_into_home(true, []),
};
