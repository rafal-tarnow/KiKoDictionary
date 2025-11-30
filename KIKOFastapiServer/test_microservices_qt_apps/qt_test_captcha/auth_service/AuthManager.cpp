#include "AuthManager.hpp"
#include <QByteArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>

AuthManager::AuthManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(this)
    , m_settings(this)
{
    loadTokens();
}

AuthManager::~AuthManager() {}

void AuthManager::setAccessToken(const QString &token)
{
    if (m_accessToken != token) {
        m_accessToken = token;
        emit accessTokenChanged();
        setLoggedIn(!m_accessToken.isEmpty());
        saveTokens();
    }
}

void AuthManager::setRefreshToken(const QString &token)
{
    if (m_refreshToken != token) {
        m_refreshToken = token;
        emit refreshTokenChanged();
        saveTokens();
    }
}

void AuthManager::setResponseMessage(const QString &message)
{
    if (m_responseMessage != message) {
        m_responseMessage = message;
        qDebug() << "Response message: " << message;
        emit responseMessageChanged();
    }
}

void AuthManager::setLoggedIn(bool loggedIn)
{
    if (m_loggedIn != loggedIn) {
        m_loggedIn = loggedIn;
        emit loggedInChanged();
    }
}

void AuthManager::saveTokens()
{
    m_settings.setValue("tokens/accessToken", encryptToken(m_accessToken));
    m_settings.setValue("tokens/refreshToken", encryptToken(m_refreshToken));
    m_settings.sync();
}

void AuthManager::loadTokens()
{
    QString encryptedAccessToken = m_settings.value("tokens/accessToken").toString();
    QString encryptedRefreshToken = m_settings.value("tokens/refreshToken").toString();

    setAccessToken(decryptToken(encryptedAccessToken));
    setRefreshToken(decryptToken(encryptedRefreshToken));
}

void AuthManager::clearTokens()
{
    m_settings.remove("tokens/accessToken");
    m_settings.remove("tokens/refreshToken");
    m_settings.sync();
    setAccessToken("");
    setRefreshToken("");
}

QString AuthManager::encryptToken(const QString &token) const
{
    if (token.isEmpty())
        return "";
    QByteArray data = token.toUtf8();
    QByteArray result;
    result.resize(data.size());
    for (int i = 0; i < data.size(); ++i) {
        result[i] = data[i] ^ m_encryptionKey[i % m_encryptionKey.size()];
    }
    return QString(result.toBase64());
}

QString AuthManager::decryptToken(const QString &encryptedToken) const
{
    if (encryptedToken.isEmpty())
        return "";
    QByteArray data = QByteArray::fromBase64(encryptedToken.toUtf8());
    QByteArray result;
    result.resize(data.size());
    for (int i = 0; i < data.size(); ++i) {
        result[i] = data[i] ^ m_encryptionKey[i % m_encryptionKey.size()];
    }
    return QString::fromUtf8(result);
}

void AuthManager::registerUser(const QString &email,
                               const QString &username,
                               const QString &password)
{
    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/auth/register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["username"] = username;
    json["password"] = password;

    QJsonDocument doc(json);
    QNetworkReply *reply = m_networkManager.post(request, doc.toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleReply(reply, "Register");
    });
}

void AuthManager::loginUser(const QString &email, const QString &password)
{
    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/auth/login"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QUrlQuery params;
    params.addQueryItem("username", email);
    params.addQueryItem("password", password);

    QNetworkReply *reply = m_networkManager.post(request,
                                                 params.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        qDebug() << "Login reply received";
        handleReply(reply, "Login");
    });
}

void AuthManager::logoutUser()
{
    if (m_refreshToken.isEmpty()) {
        setResponseMessage("No refresh token available.");
        return;
    }

    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/auth/logout"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["refresh_token"] = m_refreshToken;

    QJsonDocument doc(json);
    QNetworkReply *reply = m_networkManager.post(request, doc.toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleReply(reply, "Logout");
    });
}

void AuthManager::refreshAccessToken()
{
    if (m_refreshToken.isEmpty()) {
        setResponseMessage("No refresh token available.");
        return;
    }

    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/auth/refresh"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["refresh_token"] = m_refreshToken;

    QJsonDocument doc(json);
    QNetworkReply *reply = m_networkManager.post(request, doc.toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleReply(reply, "Refresh");
    });
}

void AuthManager::getTestData()
{
    if (m_accessToken.isEmpty()) {
        setResponseMessage("No access token available.");
        return;
    }

    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/data/test-data"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", ("Bearer " + m_accessToken).toUtf8());

    QNetworkReply *reply = m_networkManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleReply(reply, "GetTestData");
    });
}

void AuthManager::handleReply(QNetworkReply *reply, const QString &operation)
{
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "Response Login ERROR";
        setResponseMessage(QString("%1 failed: %2").arg(operation, reply->errorString()));
        reply->deleteLater();
        return;
    }
    qDebug() << "Response Login OK";
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    qDebug() << "Status code: " << statusCode;
    QByteArray responseData = reply->readAll();
    qDebug() << "responseData: " << responseData;
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    QString message;

    if (operation == "Register") {
        if (statusCode == 201) {
            QJsonObject json = doc.object();
            message = QString("Registered user: %1").arg(json["username"].toString());
        } else if (statusCode == 409) {
            message = QString("Registration failed: %1").arg(doc.object()["detail"].toString());
        } else if (statusCode == 422) {
            message = QString("Registration failed: Invalid input - %1")
                          .arg(doc.toJson(QJsonDocument::Compact));
        } else {
            message = QString("Registration failed with status %1").arg(statusCode);
        }
    } else if (operation == "Login") {
        if (statusCode == 200) {
            QJsonObject json = doc.object();
            setAccessToken(json["access_token"].toString());
            setRefreshToken(json["refresh_token"].toString());
            message = "Login successful";
        } else if (statusCode == 401) {
            message = "Login failed: Incorrect username or password";
        } else {
            message = QString("Login failed with status %1").arg(statusCode);
        }
    } else if (operation == "Logout") {
        if (statusCode == 204) {
            clearTokens();
            message = "Logout successful";
        } else {
            message = QString("Logout failed with status %1").arg(statusCode);
        }
    } else if (operation == "Refresh") {
        if (statusCode == 200) {
            QJsonObject json = doc.object();
            setAccessToken(json["access_token"].toString());
            setRefreshToken(json["refresh_token"].toString());
            message = "Token refresh successful";
        } else if (statusCode == 401) {
            message = "Token refresh failed: Invalid or expired refresh token";
            clearTokens();
        } else {
            message = QString("Token refresh failed with status %1").arg(statusCode);
        }
    } else if (operation == "GetTestData") {
        if (statusCode == 200) {
            QJsonObject json = doc.object();
            message = QString("Test data: %1").arg(json["message"].toString());
        } else if (statusCode == 401) {
            message = "Failed to get test data: Unauthorized";
        } else {
            message = QString("Failed to get test data with status %1").arg(statusCode);
        }
    }

    setResponseMessage(message);
    reply->deleteLater();
}
