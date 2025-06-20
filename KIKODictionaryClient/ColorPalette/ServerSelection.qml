// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtExampleStyle

pragma ComponentBehavior: Bound

Rectangle {
    id: root
    // A popup for selecting the server URL

    signal serverSelected()

    required property PaginatedResource colorResources
    required property PaginatedResource colorUsers
    required property RestService restPalette

    Connections {
        target: root.colorUsers
        // Closes the URL selection popup once we have received data successfully
        function onDataUpdated() {
            fetchTester.stop()
            root.serverSelected()
        }
    }


    ListModel {
        id: server
        ListElement {
            title: qsTr("Public REST API Test Server")
            url: "https://reqres.in/api"
            //url: "http://192.168.0.129:49425/api"
            icon: "qrc:/qt/qml/ColorPalette/icons/testserver.png"
        }
        ListElement {
            title: qsTr("Production REST API server")
            url: "https://sentences.rafal-kruszyna.org/api"
            icon: "qrc:/qt/qml/ColorPalette/icons/qt.png"
        }
        ListElement {
            title: qsTr("Development REST API server")
            url: "https://192.168.0.129:8000/api"
            icon: "qrc:/qt/qml/ColorPalette/icons/qt.png"
        }
    }


    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/qt/qml/ColorPalette/icons/qt.png"
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 20
            Layout.preferredHeight: 50
        }

        Label {
            text: qsTr("Choose a server")
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 50

            font.pixelSize: 24
        }

        component ServerListDelegate: Rectangle {
            id: serverListDelegate
            required property string title
            required property string url
            required property string icon
            required property int index

            radius: 10
            color: "#00000000"

            border.color: ListView.view.currentIndex === index ? "#2CDE85" : "#E0E2E7"
            border.width: 2

            implicitWidth: 250
            implicitHeight: 100

            Rectangle {
                id: img
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.leftMargin: 20

                width: 30
                height: 30
                radius: 200
                border. color: "#E7F4EE"
                border.width: 5

                Image {
                        anchors.centerIn: parent
                        source: serverListDelegate.icon
                        width: 15
                        height: 15
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                Text {
                    text: parent.url

                    anchors.left: parent.left
                    anchors.top: img.bottom
                    anchors.topMargin: 10
                    anchors.leftMargin: 20
                    color: "#667085"
                    font.pixelSize: 13
                }
                Text {
                    text: parent.title

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    color: "#222222"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                anchors.fill: parent
                onClicked: serverList.currentIndex = serverListDelegate.index;
            }
        }

        ListView {
            id: serverList
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumHeight: 200
            Layout.preferredWidth: 250
            //Layout.preferredHeight: parent.height*0.6
            Layout.fillHeight: true
            orientation: ListView.Vertical
            clip: true

            model: server
            spacing: 20

            delegate: ServerListDelegate {
            }
        }



        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            text: restPalette.sslSupported ? qsTr("Connect (SSL)") : qsTr("Connect")

            buttonColor: "#2CDE85"
            textColor: "#FFFFFF"

            onClicked: {
                console.log("connect ...")
                busyIndicatorPopup.title = (serverList.currentItem as ServerListDelegate).title
                busyIndicatorPopup.icon = (serverList.currentItem as ServerListDelegate).icon
                busyIndicatorPopup.open()

                fetchTester.test((serverList.currentItem  as ServerListDelegate).url)
            }
        }

        Timer {
            id: fetchTester
            interval: 2000

            function test(url) {
                console.log("fetchTester.test()")
                root.restPalette.url = url
                //root.colorResources.refreshCurrentPage()
                root.colorUsers.refreshCurrentPage()
                start()
            }
            onTriggered: busyIndicatorPopup.close()
        }

    }

    onVisibleChanged: {if (!visible) busyIndicatorPopup.close();}

    Popup {
        id: busyIndicatorPopup
        padding: 10
        modal: true
        focus: true
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        property alias title: titleText.text
        property alias icon: titleImg.source

        ColumnLayout {
            id: fetchIndicator
            anchors.fill: parent

            RowLayout {
                Rectangle {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    radius: 200
                    border. color: "#E7F4EE"
                    border.width: 5

                    Image {
                        id: titleImg
                        anchors.centerIn: parent
                        width: 25
                        height: 25
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Label {
                    id: titleText
                    text:""
                    font.pixelSize: 18
                }
            }

            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignHCenter
                BusyIndicator {
                    running: visible
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("Testing URL")
                    font.pixelSize: 18
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Cancel")
                onClicked: {
                    busyIndicatorPopup.close()
                }
            }

        }

    }

    Text{
        font.pointSize: 5
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        color: "red"
        text: "build: 2"
    }
}
