import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import QtExampleStyle

Page {
    id: root
    required property PaginatedResource sentences
    required property PaginatedResource colors

    visible: true

    Action {
        id: addSentenceAction
        onTriggered: sentenceEditor.createNewSentence()
    }

    SentenceDialogEditor{
        id: sentenceEditor
        width: parent.width

        onSentenceAdded: (sentence, english_translation) => {
                             console.log(sentence + " " + english_translation)
                             root.sentences.add({"sentence" : sentence,
                                                    "language" : "pl",
                                                    "translation" : english_translation})
                         }
        onSentenceUpdated: (sentence, english_translation, sid) => {
                               console.log("onSentenceUpdate: " + sentence + " " + english_translation + " " + sid)
                               root.sentences.update({"sentence" : sentence,
                                                         "language" : "pl",
                                                         "translation" : english_translation},
                                                     sid)
                           }
    }

    SentenceDialogDelete {
        id: colorDeletePopup
        onDeleteClicked: (cid) => {
                             root.sentences.remove(cid)
                         }
    }

    onVisibleChanged: {
        if(root.visible){
            root.sentences.refreshCurrentPage()
        }
    }

    background: Rectangle{
        anchors.fill: parent
        color: "#efeae2"
    }


    contentItem: Item {
        ListView{
            id: sentencesListView
            anchors.fill: parent
            spacing: 10
            clip: true
            footerPositioning: ListView.OverlayFooter
            model: root.sentences.data

            delegate: ItemDelegate {
                id: sentenceItem
                required property var modelData
                width: sentencesListView.width
                height: translationBackground.height > sentenceBackground.height ? (translationBackground.height + editButton.height): (sentenceBackground.height + editButton.height)
                spacing: 10
                z: -1


                Rectangle{
                    id: sentenceBackground
                    color: "#ffffff"
                    anchors.top: sentenceTxt.top
                    anchors.right: sentenceTxt.right
                    anchors.left: sentenceTxt.left
                    height: sentenceTxt.height > translationTxt.height ? sentenceTxt.height : translationTxt.height
                    radius: 10
                    border.width: 1
                    border.color: "#e6d5bb"
                }

                TextEdit{
                    id: sentenceTxt
                    width: parent.width/2
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.horizontalCenter
                    anchors.margins: 5
                    text: sentenceItem.modelData.sentence
                    wrapMode: Text.Wrap
                    readOnly: true
                    selectByMouse: true
                    focus: true
                    // Rectangle{
                    //     color: "#44FF0000"
                    //     anchors.fill: parent
                    //     border.color: "#FF0000"
                    // }
                }


                Rectangle{
                    id: translationBackground
                    //color: UIStyle.colorSecondary_2
                    color: "#d9fdd3"
                    height: sentenceTxt.height > translationTxt.height ? sentenceTxt.height : translationTxt.height
                    anchors.top: translationTxt.top
                    anchors.right: translationTxt.right
                    anchors.left: translationTxt.left
                    border.width: 1
                    border.color: "#aeffa1"
                    radius: 10


                }


                TextEdit{
                    id: translationTxt
                    anchors.top: parent.top
                    anchors.left: parent.horizontalCenter
                    anchors.right: parent.right
                    anchors.margins: 5
                    text: sentenceItem.modelData.translation
                    wrapMode: Text.Wrap
                    readOnly: true
                    selectByMouse: true
                    focus: true
                }



                ToolButton {
                    id: deleteButton
                    anchors.top: translationBackground.bottom
                    anchors.right: editButton.left
                    icon.source: UIStyle.iconPath("delete")
                    //enabled: root.loginService.loggedIn
                    onClicked: colorDeletePopup.maybeDelete(sentenceItem.modelData)
                }

                ToolButton{
                    id: editButton
                    anchors.top: translationBackground.bottom
                    anchors.right: translationBackground.right
                    icon.source: UIStyle.iconPath("edit")
                    //enabled: root.loginService.loggedIn
                    onClicked: sentenceEditor.updateSentence(sentenceItem.modelData)
                }

                Rectangle{
                    id: delegateBoundary
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "red"
                    border.width: 1
                    visible: false
                }

            }

            footer : ToolBar{
                visible: root.sentences.pages > 1
                implicitWidth: parent.width
                RowLayout {
                    anchors.fill: parent

                    Item { Layout.fillWidth: true /* spacer */ }

                    Repeater {
                        model: root.sentences.pages

                        ToolButton {
                            id: pageButton
                            text: page
                            font.bold: root.sentences.page === page

                            required property int index
                            readonly property int page: (index + 1)

                            onClicked: root.sentences.page = page

                            Component.onCompleted: {
                                pageButton.contentItem.color = "black"
                            }
                        }
                    }
                }

                background: Rectangle{
                    anchors.fill: parent
                    color: "#f0f2f5"
                }
            }


        }


        RoundButton{
            id: addButton
            text: qsTr("+")
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            height: 50
            width: 50
            radius: 80
            z: 2
            Material.background: Material.Pink
            visible: true
            action: addSentenceAction
            Component.onCompleted: {
                addButton.contentItem.color = "white"
                addButton.contentItem.font.pointSize = "15"
            }
        }

    }

    // footer: ToolBar {

    //     visible: root.sentences.pages > 1
    //     implicitWidth: parent.width

    //     RowLayout {
    //         anchors.fill: parent

    //         Item { Layout.fillWidth: true}

    //         Repeater {
    //             model: root.sentences.pages

    //             ToolButton {
    //                 text: page
    //                 font.bold: root.sentences.page === page

    //                 required property int index
    //                 readonly property int page: (index + 1)

    //                 onClicked: root.sentences.page = page
    //             }
    //         }
    //     }
    // }

}
