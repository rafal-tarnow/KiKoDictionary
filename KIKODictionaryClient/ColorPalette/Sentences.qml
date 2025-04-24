import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

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
    }

    onVisibleChanged: {
        if(root.visible){
            root.sentences.refreshCurrentPage()
        }
    }

     contentItem: Item {
         ListView{
             id: sentencesListView
             anchors.fill: parent

             model: root.sentences.data

             delegate: ItemDelegate {
                 id: sentenceItem
                 required property var modelData
                 width: sentencesListView.width
                 height: 25
                 spacing: 10
                 RowLayout{
                     anchors.fill: parent
                     Text{
                         text: sentenceItem.modelData.polish_sentence
                     }
                     Text{
                         text: sentenceItem.modelData.english_sentence
                     }

                 }
             }


         }

         RoundButton{
             id: addButton
             text: qsTr("+")
             anchors.right: parent.right
             anchors.bottom: parent.bottom
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
