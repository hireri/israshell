import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.style
import qs.settings.components

PageBase {
    title: Config.ai.name
    subtitle: "AI assistant configuration"

    property var ai: Config.ai

    function updateAi(changes) {
        Config.update({
            ai: Object.assign({}, Config.ai, changes)
        });
    }

    function activeProvider() {
        return ai.providers.find(p => p.id === ai.activeProvider) ?? ai.providers[0];
    }

    function updateProvider(changes) {
        const providers = ai.providers.map(p => p.id === ai.activeProvider ? Object.assign({}, p, changes) : p);
        updateAi({
            providers
        });
    }

    SectionCard {
        label: "Identity"
        Layout.fillWidth: true

        SettingInput {
            label: "Name"
            sublabel: "How the assistant refers to itself"
            iconBg: Colors.md3.tertiary_container
            value: ai.name
            fieldWidth: 160
            onCommitted: v => updateAi({
                    name: v
                })
        }

        SettingRow {
            label: "System prompt"
            iconBg: Colors.md3.tertiary_container

            ScrollView {
                width: 320
                height: 90
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: promptArea
                    text: ai.systemPrompt
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.on_surface
                    wrapMode: TextArea.Wrap
                    background: Rectangle {
                        radius: 8
                        color: Colors.md3.surface_container_high
                        border.width: promptArea.activeFocus ? 1.5 : 1
                        border.color: promptArea.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    onEditingFinished: updateAi({
                        systemPrompt: promptArea.text
                    })
                }
            }
        }

        SettingSlider {
            isLast: true
            label: "Temperature"
            sublabel: "Response creativity (0 = focused, 2 = creative)"
            iconBg: Colors.md3.tertiary_container
            from: 0
            to: 2
            stepSize: 0.1
            unit: ""
            decimals: 1
            value: ai.temperature
            onMoved: v => updateAi({
                    temperature: Math.round(v * 10) / 10
                })
        }
    }

    SectionCard {
        label: "Backend"
        Layout.fillWidth: true

        SettingRow {
            label: "Provider"
            iconBg: Colors.md3.tertiary_container

            Row {
                spacing: 6

                Repeater {
                    model: ai.providers

                    Rectangle {
                        required property var modelData
                        property bool active: ai.activeProvider === modelData.id

                        height: 30
                        width: chipLbl.implicitWidth + 24
                        radius: 15
                        color: active ? Colors.md3.secondary_container : "transparent"
                        border.width: 1
                        border.color: active ? "transparent" : Colors.md3.surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: chipLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: active ? Font.Medium : Font.Normal
                            color: active ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: updateAi({
                                activeProvider: modelData.id
                            })
                        }
                    }
                }

                Rectangle {
                    height: 30
                    width: 30
                    radius: 15
                    color: Colors.md3.surface_container_high
                    border.width: 1
                    border.color: Colors.md3.surface_variant

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 16
                        color: Colors.md3.outline
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const newProvider = {
                                id: "provider_" + Date.now(),
                                type: "openai",
                                label: "New provider",
                                endpoint: "http://localhost:1234/v1",
                                model: "",
                                apiKey: ""
                            };
                            updateAi({
                                providers: [...ai.providers, newProvider]
                            });
                        }
                    }
                }
            }
        }

        SettingInput {
            label: "Endpoint"
            iconBg: Colors.md3.tertiary_container
            value: activeProvider().endpoint
            fieldWidth: 220
            onCommitted: v => updateProvider({
                    endpoint: v
                })
        }

        SettingInput {
            label: "Model"
            iconBg: Colors.md3.tertiary_container
            value: activeProvider().model
            fieldWidth: 180
            onCommitted: v => updateProvider({
                    model: v
                })
        }

        SettingInput {
            isLast: true
            label: "API key"
            sublabel: "Not needed for local providers"
            iconBg: Colors.md3.tertiary_container
            value: activeProvider().apiKey
            password: true
            fieldWidth: 180
            placeholder: "sk-..."
            onCommitted: v => updateProvider({
                    apiKey: v
                })
        }
    }

    SectionCard {
        label: "Tools"
        Layout.fillWidth: true

        SettingRow {
            isLast: true
            label: "Enabled capabilities"
            sublabel: "Exposed to the model via MCP"
            iconBg: Colors.md3.tertiary_container

            Flow {
                width: 280
                spacing: 6

                ToolChip {
                    label: "Memory"
                    active: ai.tools.includes("memory")
                    onToggled: v => {
                        const t = v ? [...ai.tools, "memory"] : ai.tools.filter(x => x !== "memory");
                        updateAi({
                            tools: t
                        });
                    }
                }
                ToolChip {
                    label: "Web search"
                    active: ai.tools.includes("ddg-search")
                    onToggled: v => {
                        const t = v ? [...ai.tools, "ddg-search"] : ai.tools.filter(x => x !== "ddg-search");
                        updateAi({
                            tools: t
                        });
                    }
                }
                ToolChip {
                    label: "Shell exec"
                    active: ai.tools.includes("shell_exec")
                    onToggled: v => {
                        const t = v ? [...ai.tools, "shell_exec"] : ai.tools.filter(x => x !== "shell_exec");
                        updateAi({
                            tools: t
                        });
                    }
                }
            }
        }
    }
}
