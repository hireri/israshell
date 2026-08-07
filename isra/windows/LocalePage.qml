pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.components
import qs.windows.components

PageBase {
    id: page
    title: Localization.t("settingsWindow.locale")
    subtitle: Localization.t("localePage.time_date_and_regional_preferences")

    readonly property var _requestableLanguages: [
        {
            code: "en_US",
            name: "English"
        },
        {
            code: "es_ES",
            name: "Español"
        },
        {
            code: "fr_FR",
            name: "Français"
        },
        {
            code: "de_DE",
            name: "Deutsch"
        },
        {
            code: "it_IT",
            name: "Italiano"
        },
        {
            code: "pt_BR",
            name: "Português (Brasil)"
        },
        {
            code: "pt_PT",
            name: "Português"
        },
        {
            code: "ru_RU",
            name: "Русский"
        },
        {
            code: "ja_JP",
            name: "日本語"
        },
        {
            code: "ko_KR",
            name: "한국어"
        },
        {
            code: "zh_CN",
            name: "简体中文"
        },
        {
            code: "zh_TW",
            name: "繁體中文"
        },
        {
            code: "ar_SA",
            name: "العربية"
        },
        {
            code: "hi_IN",
            name: "हिन्दी"
        },
        {
            code: "tr_TR",
            name: "Türkçe"
        },
        {
            code: "nl_NL",
            name: "Nederlands"
        },
        {
            code: "pl_PL",
            name: "Polski"
        },
        {
            code: "sv_SE",
            name: "Svenska"
        },
        {
            code: "da_DK",
            name: "Dansk"
        },
        {
            code: "no_NO",
            name: "Norsk"
        },
        {
            code: "fi_FI",
            name: "Suomi"
        },
        {
            code: "cs_CZ",
            name: "Čeština"
        },
        {
            code: "el_GR",
            name: "Ελληνικά"
        },
        {
            code: "he_IL",
            name: "עברית"
        },
        {
            code: "th_TH",
            name: "ไทย"
        },
        {
            code: "vi_VN",
            name: "Tiếng Việt"
        },
        {
            code: "uk_UA",
            name: "Українська"
        },
        {
            code: "ro_RO",
            name: "Română"
        },
        {
            code: "hu_HU",
            name: "Magyar"
        },
        {
            code: "id_ID",
            name: "Bahasa Indonesia"
        }
    ]

    readonly property var _installedLanguages: {
        const opts = [
            {
                label: "English",
                value: "en_US"
            }
        ];
        for (const code in Localization.manifest) {
            const entry = Localization.manifest[code];
            const label = (typeof entry === "object" ? entry.label : entry) ?? code;
            opts.push({
                label: label + (Localization.isOutdated(code) ? Localization.t("localization.outdated_suffix") : ""),
                value: code
            });
        }
        return opts;
    }

    function _resolveManifestEntry(id) {
        const entry = Localization.manifest[id];
        if (!entry)
            return null;
        if (typeof entry === "object" && entry.code)
            return entry;

        const knownTones = Object.keys(Localization.toneLabels ?? {
                formal: true,
                playful: true,
                concise: true
            });
        for (const tone of knownTones) {
            if (tone === "formal")
                continue;
            const suffix = "_" + tone;
            if (id.endsWith(suffix)) {
                const code = id.slice(0, -suffix.length);
                const known = page._requestableLanguages.find(l => l.code === code);
                if (known)
                    return {
                        code: code,
                        tone: tone,
                        sourceName: known.name
                    };
            }
        }

        const known = page._requestableLanguages.find(l => l.code === id);
        return {
            code: id,
            tone: "formal",
            sourceName: known ? known.name : (typeof entry === "string" ? entry : id)
        };
    }

    readonly property var _providerOptions: Object.keys(Config.aiAssistant.providers).map(id => ({
                label: id,
                value: id
            }))

    property string _translationProvider: Config.aiAssistant.providers[Config.translationProvider] ? Config.translationProvider : Config.aiAssistant.provider

    readonly property var _pendingOptions: page._requestableLanguages.filter(l => {
            const id = Localization.localeId(l.code, Config.translationTone);
            return id !== "en_US" && !(id in Localization.manifest);
        }).map(l => ({
                label: l.name,
                value: l.code
            }))

    readonly property var _providerCfg: Config.aiAssistant.providers[page._translationProvider]
    readonly property bool _hasProviderKey: page._providerCfg && (!page._providerCfg.requiresAuth || Secrets.get(page._translationProvider) !== "")

    property string _pendingCode: page._pendingOptions.length > 0 ? page._pendingOptions[0].value : ""
    property string _pendingName: {
        const found = page._requestableLanguages.find(l => l.code === page._pendingCode);
        return found ? found.name : page._pendingCode;
    }

    readonly property string _regenTargetId: {
        const entry = page._resolveManifestEntry(Config.language);
        return entry ? Localization.localeId(entry.code, entry.tone) : "";
    }
    readonly property string _pendingTargetId: Localization.localeId(page._pendingCode, Config.translationTone)
    readonly property bool _regenRunning: Localization.translating && Localization.translatingId === page._regenTargetId
    readonly property bool _pendingRunning: Localization.translating && Localization.translatingId === page._pendingTargetId

    SectionCard {
        label: Localization.t("localePage.language")
        Layout.fillWidth: true

        SettingSelect {
            label: Localization.t("localePage.language")
            sublabel: Localization.t("localePage.language_sublabel")
            options: page._installedLanguages
            currentValue: Config.language
            onSelected: v => Config.update({
                    language: v
                })
        }

        SettingRow {
            visible: Localization.activeLocaleOutdated
            label: Localization.t("localization.outdated_banner_title")
            sublabel: page._regenRunning ? Localization.t("localePage.contacting_gemini") : Localization.t("localization.outdated_banner_body")

            Rectangle {
                anchors.verticalCenter: parent?.verticalCenter
                implicitWidth: (page._regenRunning ? regenSpinner.width : regenTxt.implicitWidth) + 26
                implicitHeight: 32
                radius: height / 2
                color: regenMa.containsMouse ? Colors.md3.primary : Colors.md3.primary_container
                opacity: (page._hasProviderKey && !Localization.translating) ? 1 : 0.5
                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: regenTxt
                    anchors.centerIn: parent
                    visible: !page._regenRunning
                    text: Localization.t("localization.regenerate")
                    color: regenMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }

                LoadingSpinner {
                    id: regenSpinner
                    anchors.centerIn: parent
                    visible: page._regenRunning
                    running: page._regenRunning
                    size: 16
                    color: regenMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                }

                MouseArea {
                    id: regenMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Localization.translating ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: page._hasProviderKey && !Localization.translating
                    onClicked: {
                        const entry = page._resolveManifestEntry(Config.language);
                        if (!entry)
                            return;
                        Localization.requestTranslation(entry.code, entry.sourceName, page._translationProvider, true, entry.tone);
                    }
                }
            }
        }

        SettingSelect {
            label: Localization.t("localePage.translation_provider")
            sublabel: Localization.t("localePage.translation_provider_sublabel")
            options: page._providerOptions
            currentValue: page._translationProvider
            onSelected: v => {
                page._translationProvider = v;
                Config.update({
                    translationProvider: v
                });
            }
        }

        SettingChips {
            label: Localization.t("localePage.translation_tone")
            sublabel: Localization.t("localePage.translation_tone_sublabel")
            options: [
                {
                    label: Localization.t("localePage.tone_formal"),
                    value: "formal"
                },
                {
                    label: Localization.t("localePage.tone_playful"),
                    value: "playful"
                },
                {
                    label: Localization.t("localePage.tone_concise"),
                    value: "concise"
                }
            ]
            currentValue: Config.translationTone
            onSelected: v => Config.update({
                    translationTone: v
                })
        }

        SettingSelect {
            isLast: true
            label: Localization.t("localePage.request_new_language")
            sublabel: {
                if (!page._hasProviderKey)
                    return Localization.t("localePage.set_gemini_key_hint");
                if (page._pendingRunning)
                    return Localization.t("localePage.contacting_gemini");
                if (Localization.translateError !== "")
                    return Localization.translateError;
                return Localization.t("localePage.request_new_language_sublabel");
            }
            options: page._pendingOptions
            currentValue: page._pendingCode
            enabled: page._hasProviderKey && page._pendingOptions.length > 0 && !Localization.translating
            onSelected: v => page._pendingCode = v

            Rectangle {
                id: requestBtn
                anchors.verticalCenter: parent?.verticalCenter
                implicitWidth: (page._pendingRunning ? requestSpinner.width : requestTxt.implicitWidth) + 26
                implicitHeight: 32
                radius: height / 2
                color: requestMa.containsMouse ? Colors.md3.primary : Colors.md3.primary_container
                opacity: (page._hasProviderKey && page._pendingCode !== "" && !Localization.translating) ? 1 : 0.5
                Behavior on color {
                    ColorAnimation {
                        duration: 90
                    }
                }
                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: requestTxt
                    anchors.centerIn: parent
                    visible: !page._pendingRunning
                    text: Localization.t("localePage.request")
                    color: requestMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }

                LoadingSpinner {
                    id: requestSpinner
                    anchors.centerIn: parent
                    visible: page._pendingRunning
                    running: page._pendingRunning
                    size: 16
                    color: requestMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                }

                MouseArea {
                    id: requestMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Localization.translating ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: page._hasProviderKey && page._pendingCode !== "" && !Localization.translating
                    onClicked: Localization.requestTranslation(page._pendingCode, page._pendingName, page._translationProvider)
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("widgetService.clock")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("localePage.hour_format")
            options: [
                {
                    label: Localization.t("localePage.12h"),
                    value: 1
                },
                {
                    label: Localization.t("localePage.24h"),
                    value: 0
                }
            ]
            currentValue: Config.hourFormat
            onSelected: v => Config.update({
                    hourFormat: v
                })
        }

        SettingSwitch {
            label: Localization.t("clockPage.show_seconds")
            enabled: Config.timeFormat === ""
            opacity: Config.timeFormat === "" ? 1 : 0.6
            sublabel: Localization.t("localePage.display_seconds_in_the_bar")
            checked: Config.showSeconds
            onToggled: v => Config.update({
                    showSeconds: v
                })
        }

        SettingInput {
            label: Localization.t("localePage.custom_time_format")
            sublabel: Localization.t("localePage.overrides_clock_settings_leave_empty")
            value: Config.timeFormat
            placeholder: Localization.t("localePage.hh_mm")
            onCommitted: v => Config.update({
                    timeFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("localePage.show_bar_clock")
            sublabel: Localization.t("localePage.display_the_system_time_in")
            checked: Config.bar.showClock ?? true
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    showClock: v
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("localePage.date")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("localePage.week_starts_on_monday")
            sublabel: Localization.t("localePage.iso_week_monday_as_first")
            checked: Config.weekMonday
            onToggled: v => Config.update({
                    weekMonday: v
                })
        }

        SettingChips {
            label: Localization.t("localePage.date_order")
            options: [
                {
                    label: Localization.t("localePage.day_first"),
                    value: 0
                },
                {
                    label: Localization.t("localePage.month_first"),
                    value: 1
                }
            ]
            currentValue: Config.dateOrder
            onSelected: v => Config.update({
                    dateOrder: v
                })
        }

        SettingInput {
            label: Localization.t("localePage.custom_date_format")
            sublabel: Localization.t("localePage.overrides_date_order_leave_empty")
            value: Config.dateFormat
            placeholder: Localization.t("localePage.ddd_dd_mm")
            onCommitted: v => Config.update({
                    dateFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("localePage.show_bar_date")
            sublabel: Localization.t("localePage.display_the_current_date_in")
            checked: Config.bar.showDate ?? true
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    showDate: v
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("localePage.weather_location")
        Layout.fillWidth: true

        SettingInput {
            label: Localization.t("localePage.city_name")
            sublabel: Localization.t("localePage.leave_empty_to_auto_locate")
            value: Config.cityName
            placeholder: Localization.t("localePage.e_g_paris")
            onCommitted: v => Config.update({
                    cityName: v
                })
        }

        SettingSwitch {
            label: Localization.t("localePage.show_bar_weather_info")
            sublabel: Localization.t("localePage.display_weather_icon_and_current")
            checked: Config.showBarWeather
            onToggled: v => Config.update({
                    showBarWeather: v
                })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("localePage.use_fahrenheit_units")
            sublabel: Localization.t("localePage.use_f_instead_of_c")
            checked: Config.useFahrenheit
            onToggled: v => Config.update({
                    useFahrenheit: v
                })
        }
    }
}