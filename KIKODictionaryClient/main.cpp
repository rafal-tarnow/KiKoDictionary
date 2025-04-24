// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtQml/qqmlapplicationengine.h>
#include <QtQml/qqmlcontext.h>
#include <QtGui/qguiapplication.h>
//#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    //QQuickStyle::setStyle(QLatin1String("Material"));

    QQmlApplicationEngine engine;
#ifdef Q_OS_MACOS
    engine.addImportPath(app.applicationDirPath() + "/../PlugIns");
#endif
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [](){ QCoreApplication::exit(EXIT_FAILURE);}, Qt::QueuedConnection);
    engine.loadFromModule("ColorPalette", "Main");
    //engine.load("http://127.0.0.1/Main.qml");
    //engine.load("/home/rafal/Dokumenty/GITHUB_MOJE/rafal-tarnow.github.io/PROJECT_qml_site/Main.qml");

    return QGuiApplication::exec();
}
