#include "ApiClient.h"

#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QUrlQuery>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
}

void ApiClient::login(const QString &username, const QString &password)
{
    qDebug() << "C++ login()";
    // Upewnij się, że hostAddress jest poprawnie zdefiniowane w pliku nagłówkowym
    QUrl url(hostAddress + "/api/v1/auth/login");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QUrlQuery params;
    params.addQueryItem("username", username);
    params.addQueryItem("password", password);

    QNetworkReply *reply = m_networkManager->post(request,
                                                  params.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onLoginFinished(reply); });
}

void ApiClient::onLoginFinished(QNetworkReply *reply)
{
    qDebug() << __PRETTY_FUNCTION__;
    reply->deleteLater();

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(response);
        QJsonObject jsonObj = jsonDoc.object();

        // POPRAWKA: Serwer zwraca "access_token", a nie "token"
        if (jsonObj.contains("access_token")) {
            m_jwtToken = jsonObj["access_token"].toString();
            qDebug() << "Zalogowano pomyślnie! Zapisano token:" << m_jwtToken;
        } else {
            qDebug() << "Błąd: Brak 'access_token' w odpowiedzi serwera!";
            qDebug() << "Odpowiedź:" << response;
        }
    } else {
        qDebug() << "Błąd logowania:" << reply->errorString();
        qDebug() << "Kod błędu HTTP:"
                 << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    }
}

void ApiClient::fetchProtectedData()
{
    if (m_jwtToken.isEmpty()) {
        qDebug() << "Brak tokenu, zaloguj się najpierw!";
        return;
    }

    QUrl url(hostAddress + "/api/protected-route");
    QNetworkRequest request(url);

    // Dodawanie tokenu JWT do nagłówka
    QByteArray authHeader = "Bearer " + m_jwtToken.toUtf8();
    request.setRawHeader("Authorization", authHeader);

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onDataFetched(reply); });
}

void ApiClient::onDataFetched(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() == QNetworkReply::NoError) {
        qDebug() << "Dane z serwera:" << reply->readAll();
    } else {
        // Jeśli błąd to 401 Unauthorized, token mógł wygasnąć
        if (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 401) {
            qDebug() << "Token wygasł lub jest nieprawidłowy!";
            m_jwtToken.clear(); // Wymuś ponowne logowanie lub użyj Refresh Tokena
        } else {
            qDebug() << "Błąd:" << reply->errorString();
        }
    }
}

// Funkcja pomocnicza
QJsonObject decodeJwtPayload(const QString &token)
{
    QStringList parts = token.split('.');
    if (parts.size() != 3) {
        return QJsonObject(); // Nieprawidłowy token
    }

    QByteArray payload = parts[1].toUtf8();

    // JWT używa Base64Url (bez paddingu '='). W Qt musimy użyć odpowiedniej flagi dekodowania
    QByteArray decoded = QByteArray::fromBase64(payload, QByteArray::Base64UrlEncoding);

    QJsonDocument doc = QJsonDocument::fromJson(decoded);
    return doc.object();
}
