import QtQuick
import QtQuick.Controls
import "../common"

ScrollablePage {
    id: page

    Column{
        spacing: 15
        Label{
            text: "Dev servers"
            font.bold: true
            font.pointSize: 15
        }

        Row{
            spacing: 15
            ServerMonitor{
                id: captchaServerMonitor
                serverUrl: "http://127.0.0.1:8001"
            }

            Label{
                text: qsTr("captcha-microservice\n" + captchaServerMonitor.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: captchaServerMonitor.isAlive ? "lightgreen" : "red"
            }
        }

        Row{
            spacing: 15
            ServerMonitor{
                id: usersMicroservicMonitor
                serverUrl: "http://127.0.0.1:8002"
            }

            Label{
                text: qsTr("users-microservicen\n" + usersMicroservicMonitor.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: usersMicroservicMonitor.isAlive ? "lightgreen" : "red"
            }
        }

        Row{
            spacing: 15
            ServerMonitor{
                id: sentencesServerMonitor
                serverUrl: "http://127.0.0.1:8003"
            }

            Label{
                text: qsTr("sentences-microservice\n" + sentencesServerMonitor.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: sentencesServerMonitor.isAlive ? "lightgreen" : "red"
            }
        }



        Label{
            text: "Production"
            font.bold: true
            font.pointSize: 15
        }

        Row{
            spacing: 15
            ServerMonitor{
                id: captchaServerMonitor_2
                serverUrl: "https://maia-captcha.rafal-kruszyna.org:443"
            }

            Label{
                text: qsTr("captha-microservice\n" + captchaServerMonitor_2.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: captchaServerMonitor_2.isAlive ? "lightgreen" : "red"
            }
        }


        Row{
            spacing: 15
            ServerMonitor{
                id: usersServerMonitor_2
                serverUrl: "https://maia-users.rafal-kruszyna.org:443"
            }

            Label{
                text: qsTr("users-microservice\n" + usersServerMonitor_2.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: usersServerMonitor_2.isAlive ? "lightgreen" : "red"
            }
        }
        Row{
            spacing: 15
            ServerMonitor{
                id: sentencesServerMonitor_2
                serverUrl: "https://maia-sentences.rafal-kruszyna.org:443"
            }

            Label{
                text: qsTr("sentences-microservice\n" + sentencesServerMonitor_2.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: sentencesServerMonitor_2.isAlive ? "lightgreen" : "red"
            }
        }


        Label{
            text: "Production local"
            font.bold: true
            font.pointSize: 15
        }

        Row{
            spacing: 15
            ServerMonitor{
                id: captchaServerMonitor_3
                serverUrl: "http://192.168.0.102:8001"
            }

            Label{
                text: qsTr("captha-microservice\n" + captchaServerMonitor_3.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: captchaServerMonitor_3.isAlive ? "lightgreen" : "red"
            }
        }


        Row{
            spacing: 15
            ServerMonitor{
                id: usersServerMonitor_3
                serverUrl: "http://192.168.0.102:8002"
            }

            Label{
                text: qsTr("users-microservice\n" + usersServerMonitor_3.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: usersServerMonitor_3.isAlive ? "lightgreen" : "red"
            }
        }
        Row{
            spacing: 15
            ServerMonitor{
                id: sentencesServerMonitor_3
                serverUrl: "http://192.168.0.102:8003"
            }

            Label{
                text: qsTr("sentences-microservice\n" + sentencesServerMonitor_3.serverUrl)
            }
            Rectangle{
                height: 10
                width: 10
                color: sentencesServerMonitor_3.isAlive ? "lightgreen" : "red"
            }
        }


    }
}
