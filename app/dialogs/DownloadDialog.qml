/*
 * Fedora Media Writer
 * Copyright (C) 2016 Martin Bříza <mbriza@redhat.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

import MediaWriter 1.0

import "../simple"
import "../complex"

Dialog {
    id: dialog
    title: qsTr("Write %1").arg(releases.selected.name)

    height: layout.height + $(36)
    standardButtons: StandardButton.NoButton

    width: $(640)

    function reset() {
        writeArrow.color = palette.text
        writeImmediately.checked = false
    }

    onVisibleChanged: {
        if (!visible) {
            if (drives.selected)
                drives.selected.cancel()
            releases.variant.resetStatus()
            downloadManager.cancel()
        }
        reset()
    }

    Connections {
        target: releases
        onSelectedChanged: {
            reset();
        }
    }

    Connections {
        target: drives
        onSelectedChanged: {
            writeImmediately.checked = false
        }
    }

    Connections {
        target: releases.variant
        onStatusChanged: {
            if ([Variant.FINISHED, Variant.FAILED, Variant.FAILED_DOWNLOAD].indexOf(releases.variant.status) >= 0)
                writeImmediately.checked = false
        }
    }

    contentItem: Rectangle {
        id: dialogContainer
        anchors.fill: parent
        color: palette.window
        focus: true

        states: [
            State {
                name: "preparing"
                when: releases.variant.status === Variant.PREPARING
            },
            State {
                name: "downloading"
                when: releases.variant.status === Variant.DOWNLOADING
                PropertyChanges {
                    target: messageDownload
                    visible: true
                }
                PropertyChanges {
                    target: progressBar;
                    value: releases.variant.progress.ratio
                }
            },
            State {
                name: "download_verifying"
                when: releases.variant.status === Variant.DOWNLOAD_VERIFYING
                PropertyChanges {
                    target: messageDownload
                    visible: true
                }
                PropertyChanges {
                    target: progressBar;
                    value: releases.variant.progress.ratio;
                    progressColor: Qt.lighter("green")
                }
            },
            State {
                name: "ready_no_drives"
                when: releases.variant.status === Variant.READY && drives.length <= 0
            },
            State {
                name: "ready"
                when: releases.variant.status === Variant.READY && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "writing_not_possible"
                when: releases.variant.status === Variant.WRITING_NOT_POSSIBLE
                PropertyChanges {
                    target: driveCombo;
                    enabled: false;
                    placeholderText: qsTr("Writing is not possible")
                }
            },
            State {
                name: "writing"
                when: releases.variant.status === Variant.WRITING
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: progressBar;
                    value: drives.selected.progress.ratio;
                    progressColor: "red"
                }
            },
            State {
                name: "write_verifying"
                when: releases.variant.status === Variant.WRITE_VERIFYING
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: progressBar;
                    value: drives.selected.progress.ratio;
                    progressColor: Qt.lighter("green")
                }
            },
            State {
                name: "finished"
                when: releases.variant.status === Variant.FINISHED
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: leftButton;
                    text: qsTr("Close");
                    color: "#628fcf";
                    textColor: "white"
                    onClicked: {
                        dialog.close()
                    }
                }
                PropertyChanges {
                    target: deleteButton
                    state: "ready"
                }
            },
            State {
                name: "failed_verification_no_drives"
                when: releases.variant.status === Variant.FAILED_VERIFICATION && drives.length <= 0
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: false;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed_verification"
                when: releases.variant.status === Variant.FAILED_VERIFICATION && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed_download"
                when: releases.variant.status === Variant.FAILED_DOWNLOAD
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "#628fcf";
                    onClicked: releases.variant.download()
                }
            },
            State {
                name: "failed_no_drives"
                when: releases.variant.status === Variant.FAILED && drives.length <= 0
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: false;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed"
                when: releases.variant.status === Variant.FAILED && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            }
        ]

        Keys.onEscapePressed: {
            if ([Variant.WRITING, Variant.WRITE_VERIFYING].indexOf(releases.variant.status) < 0)
                dialog.visible = false
        }

        ScrollView {
            id: contentScrollView
            anchors.fill: parent
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            flickableItem.flickableDirection: Flickable.VerticalFlick
            contentItem: Item {
                width: contentScrollView.width - $(18)
                height: layout.height + $(18)
                ColumnLayout {
                    id: layout
                    spacing: $(18)
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: $(18)
                        leftMargin: $(18)
                    }
                    ColumnLayout {
                        id: infoColumn
                        spacing: $(4)
                        Layout.fillWidth: true

                        InfoMessage {
                            id: messageDownload
                            visible: false
                            width: infoColumn.width
                            text: qsTr("The file will be saved to your Downloads folder.")
                        }

                        InfoMessage {
                            id: messageLoseData
                            visible: false
                            width: infoColumn.width
                            text: qsTr("By writing, you will lose all of the data on %1.").arg(driveCombo.currentText)
                        }

                        InfoMessage {
                            id: messageRestore
                            visible: false
                            width: infoColumn.width
                            text: qsTr("Your computer will now most likely report this drive as much smaller than it really is. To fix that after trying or installing Fedora, insert your drive again while Fedora Media Writer is running. You will be able to restore it back to its full size.")
                        }

                        InfoMessage {
                            id: messageSelectedImage
                            width: infoColumn.width
                            visible: releases.selected.isLocal
                            text: "<font color=\"gray\">" + qsTr("Selected:") + "</font> " + (releases.variant.iso ? (((String)(releases.variant.iso)).split("/").slice(-1)[0]) : ("<font color=\"gray\">" + qsTr("None") + "</font>"))
                        }

                        InfoMessage {
                            error: true
                            width: infoColumn.width
                            visible: releases.variant && releases.variant.errorString.length > 0
                            text: releases.variant ? releases.variant.errorString : ""
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: $(5)

                        Behavior on y {
                            NumberAnimation {
                                duration: 1000
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pointSize: $(9)
                            property double leftSize: releases.variant.progress.to - releases.variant.progress.value
                            property string leftStr:  leftSize <= 0                    ? "" :
                                                     (leftSize < 1024)                 ? qsTr("(%1 B left)").arg(leftSize) :
                                                     (leftSize < (1024 * 1024))        ? qsTr("(%1 KB left)").arg((leftSize / 1024).toFixed(1)) :
                                                     (leftSize < (1024 * 1024 * 1024)) ? qsTr("(%1 MB left)").arg((leftSize / 1024 / 1024).toFixed(1)) :
                                                                                         qsTr("(%1 GB left)").arg((leftSize / 1024 / 1024 / 1024).toFixed(1))
                            text: releases.variant.statusString + (releases.variant.status == Variant.DOWNLOADING ? (" " + leftStr) : "")
                            color: palette.windowText
                        }
                        Item {
                            Layout.fillWidth: true
                            height: childrenRect.height
                            AdwaitaProgressBar {
                                id: progressBar
                                width: parent.width
                                progressColor: "#54aada"
                                value: 0.0
                            }
                        }
                        AdwaitaCheckBox {
                            id: writeImmediately
                            enabled: driveCombo.count && opacity > 0.0
                            opacity: (releases.variant.status == Variant.DOWNLOADING || (releases.variant.status == Variant.DOWNLOAD_VERIFYING && releases.variant.progress.ratio < 0.95)) ? 1.0 : 0.0
                            text: qsTr("Write the image immediately when the download is finished")
                            onCheckedChanged: {
                                if (drives.selected) {
                                    drives.selected.cancel()
                                    if (checked)
                                        drives.selected.write(releases.variant)
                                }
                            }
                        }
                    }

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: $(32)
                        Image {
                            source: releases.selected.icon
                            Layout.preferredWidth: $(64)
                            Layout.preferredHeight: $(64)
                            sourceSize.width: $(64)
                            sourceSize.height: $(64)
                            fillMode: Image.PreserveAspectFit
                        }
                        Arrow {
                            id: writeArrow
                            anchors.verticalCenter: parent.verticalCenter
                            scale: $(1.4)
                            SequentialAnimation {
                                running: releases.variant.status == Variant.WRITING
                                loops: -1
                                onStopped: {
                                    if (releases.variant.status == Variant.FINISHED)
                                        writeArrow.color = "#00dd00"
                                    else
                                        writeArrow.color = palette.text
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: "red"
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: palette.text
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                            }
                        }
                        Column {
                            spacing: $(6)
                            Layout.preferredWidth: driveCombo.implicitWidth * 2.5
                            AdwaitaComboBox {
                                z: pressed ? 1 : 0
                                id: driveCombo
                                width: driveCombo.implicitWidth * 2.5
                                model: drives
                                textRole: "display"
                                Binding {
                                    target: drives
                                    property: "selectedIndex"
                                    value: driveCombo.currentIndex
                                }
                                onActivated: {
                                    if ([Variant.FINISHED, Variant.FAILED, Variant.FAILED_VERIFICATION].indexOf(releases.variant.status) >= 0)
                                        releases.variant.resetStatus()
                                }
                                placeholderText: qsTr("There are no portable drives connected")
                            }
                            AdwaitaComboBox {
                                z: pressed ? 1 : 0
                                visible: releases.selected.version.variant.arch.id == Architecture.ARM || (releases.selected.isLocal && releases.variant.iso.indexOf(".iso", releases.variant.iso.length - ".iso".length) === -1)
                                width: driveCombo.implicitWidth * 2.5
                                model: ["Raspberry Pi 2 Model B", "Raspberry Pi 3 Model B"]
                            }
                        }
                    }

                    ColumnLayout {
                        z: -1
                        Layout.maximumWidth: parent.width
                        spacing: $(3)
                        Item {
                            height: $(3)
                            width: 1
                        }
                        RowLayout {
                            height: rightButton.height
                            Layout.minimumWidth: parent.width
                            Layout.maximumWidth: parent.width
                            spacing: $(6)

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            DeleteButton {
                                id: deleteButton
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.maximumWidth: parent.width - leftButton.width - rightButton.width - parent.spacing * 2
                                state: "hidden"
                                errorText: qsTr("It was not possible to delete<br>\"<a href=\"%1\">%2</a>\".").arg(releases.variant.iso.match(".*/")).arg(releases.variant.iso)
                                onStarted: {
                                    if (releases.variant.erase())
                                        state = "success"
                                    else
                                        state = "error"
                                }
                            }
                            AdwaitaButton {
                                id: leftButton
                                Layout.alignment: Qt.AlignRight
                                Behavior on implicitWidth { NumberAnimation { duration: 80 } }
                                text: qsTr("Cancel")
                                enabled: true
                                onClicked: {
                                    if (drives.selected)
                                        drives.selected.cancel()
                                    releases.variant.resetStatus()
                                    writeImmediately.checked = false
                                    dialog.close()
                                }
                            }
                            AdwaitaButton {
                                id: rightButton
                                Layout.alignment: Qt.AlignRight
                                Behavior on implicitWidth { NumberAnimation { duration: 80 } }
                                textColor: enabled ? "white" : palette.text
                                text: qsTr("Write to Disk")
                                enabled: false
                            }
                        }
                    }
                }
            }
        }
    }
}
