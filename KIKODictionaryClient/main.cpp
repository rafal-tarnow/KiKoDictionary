// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtQml/qqmlapplicationengine.h>
#include <QtQml/qqmlcontext.h>
#include <QtGui/qguiapplication.h>
//#include <QQuickStyle>


// #include <QFile>
// #include <QSslCertificate>
// #include <QSslConfiguration>

// bool setGlobalSslCertificate(const QString& certPath)
// {
//     // 1. Wczytaj certyfikat z pliku
//     QFile certFile(certPath);
//     if (!certFile.open(QIODevice::ReadOnly)) {
//         qDebug() << "Błąd: Nie można otworzyć pliku certyfikatu:" << certPath;
//         return false;
//     }

//     // Wczytaj certyfikat w formacie PEM
//     QSslCertificate certificate(&certFile, QSsl::Pem);
//     certFile.close();

//     if (certificate.isNull()) {
//         qDebug() << "Błąd: Certyfikat jest nieprawidłowy lub uszkodzony!";
//         return false;
//     }

//     // 2. Pobierz domyślną konfigurację SSL
//     QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();

//     // Dodaj certyfikat do listy zaufanych certyfikatów
//     QList<QSslCertificate> caCerts = sslConfig.caCertificates();
//     caCerts.append(certificate);
//     sslConfig.setCaCertificates(caCerts);

//     // 3. Ustaw globalną konfigurację SSL
//     QSslConfiguration::setDefaultConfiguration(sslConfig);

//     qDebug() << "Globalna konfiguracja SSL ustawiona pomyślnie.";
//     return true;
// }








// void skonfigurujZaufanyCertyfikat() {
//     // 1. Załaduj swój certyfikat z zasobów
//     // QFile certFile("/home/rafal/fastapi_ssl/server.crt");
//     // if (!certFile.open(QIODevice::ReadOnly)) {
//     //     qWarning() << "Nie można otworzyć pliku certyfikatu z zasobów:" << certFile.errorString();
//     //     return;
//     // }

//     // // Odczytaj zawartość pliku
//     // QByteArray certData = certFile.readAll();
//     // certFile.close();

//     // Utwórz obiekt QSslCertificate
//     // QSslCertificate::fromData może zwrócić listę, jeśli plik PEM zawiera łańcuch
//     QList<QSslCertificate> certificates = QSslCertificate::fromPath(QStringLiteral(":/assets/server.crt"));
//     if (certificates.isEmpty()) {
//         qWarning() << "Nie udało się załadować certyfikatu lub plik jest pusty/nieprawidłowy.";
//         return;
//     }

//     // Możesz wziąć pierwszy lub wszystkie, jeśli twój plik .pem zawiera cały łańcuch
//     // Dla pojedynczego certyfikatu self-signed, wystarczy pierwszy.
//     QSslCertificate selfSignedCertificate = certificates.first();
//     // Lub jeśli chcesz dodać wszystkie z pliku:
//     // QList<QSslCertificate> selfSignedCertificates = certificates;


//     // 2. Pobierz domyślną konfigurację SSL
//     QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();

//     // 3. Pobierz listę aktualnie zaufanych certyfikatów CA
//     QList<QSslCertificate> caCertificates = sslConfig.caCertificates();

//     // 4. Dodaj swój certyfikat do listy zaufanych CA
//     // Jeśli używasz QList<QSslCertificate> selfSignedCertificates:
//     // caCertificates.append(selfSignedCertificates);
//     // Dla pojedynczego certyfikatu:
//     caCertificates.append(selfSignedCertificate);

//     // 5. Ustaw zaktualizowaną listę certyfikatów CA w konfiguracji SSL
//     sslConfig.setCaCertificates(caCertificates);

//     // 6. Ustaw tę konfigurację jako domyślną dla wszystkich przyszłych połączeń SSL
//     QSslConfiguration::setDefaultConfiguration(sslConfig);

//     qDebug() << "Konfiguracja SSL zaktualizowana o własny certyfikat.";
// }




int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    //QQuickStyle::setStyle(QLatin1String("Material"));





    // // Przykład użycia funkcji
    // QString certPath = "/home/rafal/fastapi_ssl/server.crt"; // Podaj ścieżkę do certyfikatu

    // if (!setGlobalSslCertificate(certPath)) {
    //     qDebug() << "Nie udało się ustawić globalnej konfiguracji SSL.";
    //     return -1;
    // }


    // skonfigurujZaufanyCertyfikat();





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
