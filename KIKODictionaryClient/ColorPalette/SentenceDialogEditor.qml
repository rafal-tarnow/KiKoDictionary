import QtQuick
import QtQuick.Controls

Dialog {
    id: root
    padding: 10
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    standardButtons: Dialog.Ok | Dialog.Cancel
    signal sentenceAdded(string sentence, string english_translation)
    signal sentenceUpdated(string sentence, string english_translation, int sid)

    property bool newSentence: true
    property int sentenceId: -1

    function createNewSentence() {
        newSentence = true
        open()
    }

    function updateSentence(data) {
        newSentence = false
        console.log("updateSentence()")
        console.log("id=" + data.id)
        console.log("sentence=" + data.sentence)
        sentenceId = data.id
        sentenceField.text = data.sentence
        englishTranslation.text = data.translation
        open()
    }

    onAccepted: {
        console.log("accpeted new sentence")
        if(root.newSentence){
            sentenceAdded(sentenceField.text, englishTranslation.text)
        }else{
            sentenceUpdated(sentenceField.text, englishTranslation.text, root.sentenceId)
        }
    }

    contentItem: Column{

        TextEdit {
            id: sentenceField
            padding: 10
            height: 100
            width: root.width
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            selectByKeyboard: true

            Rectangle{
                color: "#44FF0000"
                anchors.fill: parent
            }
        }
        TextEdit {
            id: englishTranslation
            padding: 10
            height: 100
            width: root.width
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            selectByKeyboard: true

            Rectangle{
                color: "#4400FF00"
                anchors.fill: parent
            }
        }


    }
}
