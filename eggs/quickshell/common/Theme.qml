pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: theme

    // General
    property string wallpaper: "2.jpg"
    property string fontFamily: "Roboto"
    property string iconFontFamily: "Font Awesome 6 Free"

    // Animation
    property int animationDuration: 150
    property int easingType: Easing.InOutQuad

    // Fonts
    property font barFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font barIconFont: ({
            family: iconFontFamily,
            pixelSize: 16,
            bold: true
        })

    property font powermenuIconFont: ({
            family: iconFontFamily,
            pixelSize: 56,
            bold: true
        })

    property font sliderPrefixIconFont: ({
            family: iconFontFamily,
            pixelSize: 16,
            bold: true
        })

    property font sliderValueFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font audioSelectorIconFont: ({
            family: iconFontFamily,
            pixelSize: 14,
            bold: true
        })

    property font audioSelectorArrowFont: ({
            family: iconFontFamily,
            pixelSize: 11,
            bold: true
        })

    property font audioSelectorCheckFont: ({
            family: iconFontFamily,
            pixelSize: 11,
            bold: true
        })

    property font quickSettingsToggleIconFont: ({
            family: iconFontFamily,
            pixelSize: 18,
            bold: true
        })

    property font quickSettingsToggleLabelFont: ({
            family: fontFamily,
            pixelSize: 11,
            bold: true
        })

    property font lockscreenClockFont: ({
            family: fontFamily,
            pixelSize: 96,
            bold: true
        })

    property font lockscreenDateFont: ({
            family: fontFamily,
            pixelSize: 24,
            bold: false
        })

    property font lockscreenInputFont: ({
            family: fontFamily,
            pixelSize: 16,
            bold: true
        })

    property font lockscreenButtonFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font lockscreenErrorFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font notificationHeaderFont: ({
            family: fontFamily,
            pixelSize: 18,
            bold: true
        })

    property font notificationCloseFont: ({
            family: iconFontFamily,
            pixelSize: 16,
            bold: true
        })

    property font notificationSummaryFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font notificationBodyFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: false
        })

    property font notificationActionFont: ({
            family: fontFamily,
            pixelSize: 12,
            bold: true
        })

    property font notificationEmptyFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: false
        })

    property font polkitDialogIconFont: ({
            family: iconFontFamily,
            pixelSize: 48,
            bold: true
        })

    property font polkitDialogTitleFont: ({
            family: fontFamily,
            pixelSize: 20,
            bold: true
        })

    property font polkitDialogMessageFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: false
        })

    property font polkitDialogIdentityFont: ({
            family: fontFamily,
            pixelSize: 12,
            bold: false
        })

    property font polkitDialogInputFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: false
        })

    property font polkitDialogButtonFont: ({
            family: fontFamily,
            pixelSize: 14,
            bold: true
        })

    property font polkitDialogErrorFont: ({
            family: fontFamily,
            pixelSize: 13,
            bold: false
        })

    // Bar
    property int barBaseHeight: 48
    property int barTopGap: 8
    property int barBottomGap: 0
    property int barLeftRightGap: 8
    property int barHeight: barBaseHeight + barTopGap + barBottomGap
    property int barRadius: 10
    property int barWidgetSpacing: 12
    property int barSideMargin: 16
    property int barWidgetRadius: 10
    property int barWidgetHorizontalPadding: 20
    property int barWidgetVerticalPadding: 10
    property int barWidgetContentHorizontalPadding: 12
    property int barWidgetContentSpacing: 8

    // Dashboard
    property alias dashboardMargin: theme.barSideMargin
    property int dashboardWidth: 500
    property int dashboardHeight: 500
    property int dashboardAutoCloseDelay: 500
    property int dashboardContentPadding: 12
    property int dashboardSlidersSpacing: 12
    property int dashboardAudioChoosersTopMargin: 12
    property int dashboardAudioChoosersMargin: 16
    property int dashboardAudioChoosersSpacing: 12
    property int dashboardAudioChoosersRadius: 10
    property int dashboardQuickSettingsTopMargin: 12
    property int dashboardQuickSettingsMargin: 16
    property int dashboardQuickSettingsSpacing: 12
    property int dashboardQuickSettingsRadius: 10
    property int dashboardQuickSettingsGridSpacing: 12

    property int dashboardNotificationsTopMargin: 12
    property int dashboardNotificationsMargin: 16
    property int dashboardNotificationsSpacing: 12
    property int dashboardNotificationsRadius: 10
    property int notificationListSpacing: 8
    property int notificationCardRadius: 8
    property int notificationCardMargin: 10
    property int notificationCardSpacing: 5
    property int notificationActionHeight: 30
    property int notificationActionPadding: 20
    property int notificationActionRadius: 4
    property double notificationEmptyOpacity: 0.5
    property int notificationsHeaderSpacing: 10

    // Sliders
    property int sliderHeight: 38
    property int sliderPrefixWidth: 32
    property int sliderSpacing: 8
    property int sliderRadius: 10

    // Audio Selectors
    property int audioSelectorSpacing: 8
    property int audioSelectorButtonHorizontalMargin: 16
    property int audioSelectorButtonInnerSpacing: 10
    property int audioSelectorButtonRadius: 10
    property int audioSelectorExpandDuration: 250
    property int audioSelectorItemRadius: 10
    property int audioSelectorItemLeftMarginOffset: 16
    property int audioSelectorItemRightMargin: 16
    property int audioSelectorItemSpacing: 10
    property int audioSelectorRefreshInterval: 2000

    // Quick Settings Toggles
    property int quickSettingsToggleHeight: 64
    property int quickSettingsToggleContentSpacing: 6
    property int quickSettingsToggleHoverDuration: 150
    property int quickSettingsTogglePollingInterval: 2000

    // Power Menu
    property int powermenuCardPadding: 32
    property int powermenuGridColumns: 3
    property int powermenuGridColumnSpacing: 20
    property int powermenuGridRowSpacing: 20
    property int powermenuButtonWidth: 130
    property int powermenuButtonHeight: 130
    property int powermenuButtonContentSpacing: 16
    property int powermenuButtonRadius: 10
    property int powermenuHoverAnimationDuration: 150
    property int powermenuAutoCloseDelay: 500
    property string powermenuBackgroundOverlayColor: "#C0000000"
    property string powermenuButtonHoverColor: "#20FFFFFF"

    // Lockscreen
    property int lockscreenInputWidth: 450
    property int lockscreenInputHeight: 66
    property int lockscreenInputRadius: 12
    property int lockscreenButtonWidth: 100
    property int lockscreenButtonHeight: 66
    property int lockscreenButtonRadius: 12
    property int lockscreenButtonSpacing: 12
    property int lockscreenClockTopMargin: 120
    property int lockscreenInputTopMargin: 60
    property double lockscreenBlurAmount: 1.0
    property double lockscreenBrightness: -0.15

    // Polkit
    property int polkitDialogWidth: 500
    property int polkitDialogHeight: 400
    property int polkitDialogRadius: 12
    property int polkitDialogPadding: 32
    property int polkitDialogSpacing: 16
    property int polkitDialogInputHeight: 48
    property int polkitDialogInputRadius: 10
    property int polkitDialogInputTopMargin: 8
    property int polkitDialogButtonWidth: 140
    property int polkitDialogButtonHeight: 42
    property int polkitDialogButtonRadius: 10
    property int polkitDialogButtonSpacing: 12
    property int polkitDialogButtonTopMargin: 12
}
