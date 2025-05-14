#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "captchaclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    CaptchaClient captchaClient;
    engine.rootContext()->setContextProperty("captchaClient", &captchaClient);

    // Rejestracja typu dla QML, jeśli chcesz go tworzyć dynamicznie w QML
    // qmlRegisterType<CaptchaClient>("dev.yourdomain.captcha", 1, 0, "CaptchaClient");

    const QUrl url(QStringLiteral("qrc:/Tester/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
