import QtQuick
import QtQuick.Controls
import "../common"

ScrollablePage {
    id: page

    Column{
        spacing: 15
        Row{
            spacing: 15
            ServerMonitor{
                id: captchaServerMonitor
                //serverUrl: "http://127.0.0.1:8001"

                serverUrl: "http://192.168.0.117:8001"
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
                id: captchaServerMonitor_2
                serverUrl: "https://captcha.rafal-kruszyna.org:8001"
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
                id: usersMicroservicMonitor
                serverUrl: "http://127.0.0.1:8002"
            }

            Label{
                text: qsTr("users-microservice")
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
                id: myUsersMicroservicMonitor
                serverUrl: "http://localhost:8003"
            }

            Label{
                text: qsTr("my-users-microservice")
            }
            Rectangle{
                height: 10
                width: 10
                color: myUsersMicroservicMonitor.isAlive ? "lightgreen" : "red"
            }
        }
    }
}
