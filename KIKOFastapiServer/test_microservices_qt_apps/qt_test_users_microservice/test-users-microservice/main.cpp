#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "userserviceclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    UserServiceClient serviceClient;
    engine.rootContext()->setContextProperty("userClient", &serviceClient);

    const QUrl url(QStringLiteral("qrc:/Tester/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
