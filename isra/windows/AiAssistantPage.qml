pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    id: pageRoot
    title: Localization.t("settingsWindow.ai_assistant")
    subtitle: Localization.t("settingsWindow.provider_prompt_behavior")

    readonly property string defaultSystemPrompt: "You are a helpful assistant embedded in the user's Linux desktop shell. Current time: {time} on {date}. The user is running {distro} with the {compositor} compositor, logged in as {user}. Keep answers concise and practical unless asked to go deeper."

    property bool creatingProvider: false

    function confirmAddProvider() {
        const name = providerNameField.text.trim();
        if (name)
            pageRoot.addProvider(name);
        providerNameField.text = "";
        pageRoot.creatingProvider = false;
    }

    function cancelAddProvider() {
        providerNameField.text = "";
        pageRoot.creatingProvider = false;
    }

    function prettyProviderName(key) {
        const s = key.replace(/[-_]/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function updateAiAssistant(changes) {
        Config.update({
            aiAssistant: Object.assign({}, Config.aiAssistant, changes)
        });
    }

    function updateProvider(changes) {
        const provider = Config.aiAssistant.provider;
        updateAiAssistant({
            providers: Object.assign({}, Config.aiAssistant.providers, {
                [provider]: Object.assign({}, Config.aiAssistant.providers[provider], changes)
            })
        });
    }

    function addProvider(name) {
        const slug = name.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
        if (!slug)
            return;

        let key = slug;
        let n = 2;
        while (Config.aiAssistant.providers[key] !== undefined) {
            key = slug + "-" + n;
            n++;
        }

        updateAiAssistant({
            provider: key,
            providers: Object.assign({}, Config.aiAssistant.providers, {
                [key]: {
                    apiType: "openai",
                    model: "",
                    endpoint: "https://api.openai.com/v1",
                    requiresAuth: true,
                    supportsTools: false,
                    supportsVision: false
                }
            })
        });
    }

    function removeProvider(key) {
        const keys = Object.keys(Config.aiAssistant.providers);
        if (keys.length <= 1)
            return;

        const remaining = Object.assign({}, Config.aiAssistant.providers);
        delete remaining[key];

        const nextProvider = Config.aiAssistant.provider === key ? Object.keys(remaining)[0] : Config.aiAssistant.provider;

        updateAiAssistant({
            provider: nextProvider,
            providers: remaining
        });
    }

    SectionCard {
        label: Localization.t("aiAssistantPage.general")
        Layout.fillWidth: true

        SettingSwitch {
            isLast: true
            label: Localization.t("aiAssistantPage.notify_when_finished")
            sublabel: Localization.t("aiAssistantPage.send_a_desktop_notification_when")
            checked: Config.aiAssistant.notifyOnFinish
            onToggled: v => pageRoot.updateAiAssistant({
                    notifyOnFinish: v
                })
        }
    }

    SectionCard {
        label: Localization.t("aiAssistantPage.provider")
        Layout.fillWidth: true

        SettingRow {
            label: Localization.t("aiAssistantPage.provider")
            sublabel: Localization.t("aiAssistantPage.which_provider_is_currently_active")

            RowLayout {
                spacing: 8
                anchors.verticalCenter: parent?.verticalCenter

                SelectField {
                    visible: !pageRoot.creatingProvider
                    options: Object.keys(Config.aiAssistant.providers).map(k => ({
                            label: pageRoot.prettyProviderName(k),
                            value: k
                        }))
                    currentValue: Config.aiAssistant.provider
                    onSelected: v => pageRoot.updateAiAssistant({
                            provider: v
                        })
                }

                Rectangle {
                    visible: pageRoot.creatingProvider
                    implicitWidth: 160
                    implicitHeight: 36
                    radius: 8
                    color: Config.dim(Colors.md3.surface_container_high)
                    border.width: providerNameField.activeFocus ? 2 : 1
                    border.color: providerNameField.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    TextField {
                        id: providerNameField
                        anchors.fill: parent
                        anchors.margins: 1
                        leftPadding: 12
                        rightPadding: 12
                        verticalAlignment: Text.AlignVCenter
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.on_surface
                        placeholderTextColor: Colors.md3.outline
                        placeholderText: Localization.t("aiAssistantPage.provider_name")
                        background: Item {}

                        Keys.onReturnPressed: pageRoot.confirmAddProvider()
                        Keys.onEscapePressed: pageRoot.cancelAddProvider()
                        onActiveFocusChanged: if (!activeFocus && pageRoot.creatingProvider)
                            blurCancelTimer.start()

                        Timer {
                            id: blurCancelTimer
                            interval: 80
                            onTriggered: if (pageRoot.creatingProvider)
                                pageRoot.cancelAddProvider()
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: pageRoot.creatingProvider ? Colors.md3.primary : (addProviderMa.containsMouse ? Colors.md3.secondary_container : "transparent")
                    border.width: pageRoot.creatingProvider ? 0 : 1
                    border.color: Colors.md3.surface_variant

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: pageRoot.creatingProvider ? "check" : "add"
                        iconSize: 16
                        color: pageRoot.creatingProvider ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: addProviderMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (pageRoot.creatingProvider) {
                                pageRoot.confirmAddProvider();
                            } else {
                                pageRoot.creatingProvider = true;
                                Qt.callLater(() => providerNameField.forceActiveFocus());
                            }
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    visible: Object.keys(Config.aiAssistant.providers).length > 1
                    color: deleteProviderMa.containsMouse ? Colors.md3.error_container : "transparent"
                    border.width: 1
                    border.color: Colors.md3.surface_variant

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.pixelSize: 13
                        color: deleteProviderMa.containsMouse ? Colors.md3.on_error_container : Colors.md3.outline
                    }

                    MouseArea {
                        id: deleteProviderMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pageRoot.removeProvider(Config.aiAssistant.provider)
                    }
                }
            }
        }

        SettingSelect {
            label: Localization.t("aiAssistantPage.api_type")
            sublabel: Localization.t("aiAssistantPage.protocol_used_to_talk_to_this")
            options: [
                {
                    label: "Gemini",
                    value: "gemini"
                },
                {
                    label: "OpenAI",
                    value: "openai"
                },
                {
                    label: "Ollama",
                    value: "ollama"
                }
            ]
            currentValue: Config.aiAssistant.providers[Config.aiAssistant.provider]?.apiType ?? "openai"
            onSelected: v => pageRoot.updateProvider({
                    apiType: v
                })
        }

        SettingInput {
            label: Localization.t("aiAssistantPage.model")
            value: Config.aiAssistant.providers[Config.aiAssistant.provider]?.model ?? ""
            fieldWidth: 220
            onCommitted: v => pageRoot.updateProvider({
                    model: v
                })
        }

        SettingInput {
            label: Localization.t("aiAssistantPage.endpoint")
            sublabel: Localization.t("aiAssistantPage.base_url_requests_are_sent_to")
            value: Config.aiAssistant.providers[Config.aiAssistant.provider]?.endpoint ?? ""
            fieldWidth: 260
            onCommitted: v => pageRoot.updateProvider({
                    endpoint: v
                })
        }

        SettingSwitch {
            label: Localization.t("aiAssistantPage.requires_api_key")
            sublabel: Localization.t("aiAssistantPage.whether_this_provider_needs_an_api")
            checked: Config.aiAssistant.providers[Config.aiAssistant.provider]?.requiresAuth ?? false
            onToggled: v => pageRoot.updateProvider({
                    requiresAuth: v
                })
        }

        SecretInput {
            visible: Config.aiAssistant.providers[Config.aiAssistant.provider]?.requiresAuth ?? false
            label: Localization.t("aiAssistantPage.api_key")
            sublabel: Config.aiAssistant.provider === "gemini" ? Localization.t("aiAssistantPage.shared_with_the_language_translation") : Localization.t("aiAssistantPage.key_for_the_selected_provider")
            secretKey: Config.aiAssistant.provider
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("aiAssistantPage.supports_image_attachments")
            sublabel: Localization.t("aiAssistantPage.allow_attaching_images_to_messages")
            checked: Config.aiAssistant.providers[Config.aiAssistant.provider]?.supportsVision ?? false
            onToggled: v => pageRoot.updateProvider({
                    supportsVision: v
                })
        }
    }

    SectionCard {
        label: Localization.t("aiAssistantPage.system_prompt")
        Layout.fillWidth: true

        SettingTextArea {
            isLast: true
            sublabel: Localization.t("aiAssistantPage.supports_time_date_distro_compositor")
            value: Config.aiAssistant.systemPrompt
            onCommitted: v => pageRoot.updateAiAssistant({
                    systemPrompt: v
                })

            Text {
                text: Localization.t("aiAssistantPage.reset")
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Colors.md3.primary

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pageRoot.updateAiAssistant({
                            systemPrompt: pageRoot.defaultSystemPrompt
                        })
                }
            }
        }
    }
}
