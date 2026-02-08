pragma Singleton
import Quickshell

Singleton {
    id: color

    // Primary
    property string colorPrimary: "{{colors.primary.default.hex}}"
    property string colorOnPrimary: "{{colors.on_primary.default.hex}}"
    property string colorPrimaryContainer: "{{colors.primary_container.default.hex}}"
    property string colorOnPrimaryContainer: "{{colors.on_primary_container.default.hex}}"

    // Secondary
    property string colorSecondary: "{{colors.secondary.default.hex}}"
    property string colorOnSecondary: "{{colors.on_secondary.default.hex}}"
    property string colorSecondaryContainer: "{{colors.secondary_container.default.hex}}"
    property string colorOnSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"

    // Surface
    property string colorSurface: "{{colors.surface_bright.default.hex}}"
    property string colorOnSurface: "{{colors.on_surface.default.hex}}"
    property string colorSurfaceVariant: "{{colors.surface_container_highest.default.hex}}"
    property string colorOnSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"

    // Background & Outline
    property string colorOutline: "{{colors.outline.default.hex}}"
    property string colorBackground: "{{colors.surface_container.default.hex}}"
    property string colorOnBackground: "{{colors.on_surface.default.hex}}"

    // Error
    property string colorError: "{{colors.error.default.hex}}"
    property string colorOnError: "{{colors.on_error.default.hex}}"
}
