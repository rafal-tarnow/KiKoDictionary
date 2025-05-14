// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtExampleStyle

Popup {
    id: sentenceDeleter
    padding: 10
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    signal deleteClicked(int cid)

    property int colorId: -1

    property string sentenceTxt: ""

    function maybeDelete(data) {
        console.log("maybeDelete = " + data.sentence)
        console.log("maybeDelete = " + data.id)
        sentenceTxt = data.sentence
        colorId = data.id
        open()
    }


    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            color: "#222222"
            text: qsTr("Delete Color?")
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            color: "#222222"
            text: qsTr("Are you sure, you want to delete sentence") + " \"" + sentenceDeleter.sentenceTxt + "\"?"
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                text: qsTr("Cancel")
                onClicked: sentenceDeleter.close()
            }

            Button {
                Layout.fillWidth: true
                text: qsTr("Delete")

                buttonColor: "#CC1414"
                textColor: "#FFFFFF"

                onClicked: {
                    sentenceDeleter.deleteClicked(sentenceDeleter.colorId)
                    sentenceDeleter.close()
                }
            }
       }
    }
}
