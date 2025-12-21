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
    , m_baseUrl("http://localhost:8002") // Domyślna wartość
{
    m_captchaClient = new CaptchaClient(this);
    loadTokens();
}

AuthManager::~AuthManager() {}

// Implementacja settera dla BaseUrl
void AuthManager::setBaseUrl(const QString &url)
{
    qDebug() << __PRETTY_FUNCTION__ << " = " << url;
    QString cleanUrl = url;
    // Usuwamy końcowy slash, jeśli użytkownik go podał (np. "http://localhost/"),
    // aby przy sklejaniu z "/api/..." nie powstawało "//api/...".
    if (cleanUrl.endsWith('/')) {
        cleanUrl.chop(1);
    }

    if (m_baseUrl != cleanUrl) {
        m_baseUrl = cleanUrl;
        qDebug() << "Base URL changed to:" << m_baseUrl;
        emit baseUrlChanged();

        // OPCJONALNIE: Jeśli CaptchaClient też potrzebuje znać URL,
        // tutaj powinieneś go zaktualizować, np.:
        // m_captchaClient->setBaseUrl(m_baseUrl);
    }
}

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
#warning "Ta metoda musi byc usunieta, jest niebezpieczna, nie nadaje sie na produkcje"
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
#warning "Ta metoda musi byc usunieta, jest niebezpieczna, nie nadaje sie na produkcje"
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
                               const QString &password,
                               const QString &captchaAnswer)
{
    QString capId = m_captchaClient->captchaId();

    if (capId.isEmpty()) {
        QString msg = "Captcha ID missing. Please refresh captcha.";
        setResponseMessage(msg);
        emit error(msg);
        return;
    }

    QNetworkRequest request(QUrl(m_baseUrl + "/api/v1/auth/register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["username"] = username;
    json["password"] = password;
    json["captcha_id"] = capId;
    json["captcha_answer"] = captchaAnswer;

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
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);

    qDebug() << "REPLY Status Code: " << statusCode;
    qDebug() << "REPLY JsonDocument: " << doc;

    if (reply->error() != QNetworkReply::NoError && statusCode == 0) {
        emit error("Network error: " + reply->errorString());
        setResponseMessage("Network error: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QString message;

    if (operation == "Register") {
        if (statusCode == 201) {
            QJsonObject json = doc.object();
            message = QString("Registered user: %1").arg(json["username"].toString());
            emit registerSuccess(message);
            m_captchaClient->clear();
        } else if (statusCode == 400) {
            QString detail = doc.object()["detail"].toString();
            if (detail.contains("captcha", Qt::CaseInsensitive)
                || detail.contains("answer", Qt::CaseInsensitive)) {
                message = "Incorrect Captcha answer.";
                m_captchaClient->fetchCaptcha();
            } else {
                message = "Registration failed: " + detail;
            }
            emit error(message);
        } else if (statusCode == 409) {
            message = QString("Registration failed: %1").arg(doc.object()["detail"].toString());
            emit error(message);
        } else if (statusCode == 422) {
            message = QString("Registration failed: Invalid input - %1")
                          .arg(doc.toJson(QJsonDocument::Compact));
            qDebug() << "[ERROR] " << message;
            emit error(message);
        } else {
            message = QString("Registration failed with status %1").arg(statusCode);
            emit error(message);
        }
    } else if (operation == "Login") {
        if (statusCode == 200) {
            QJsonObject json = doc.object();
            setAccessToken(json["access_token"].toString());
            setRefreshToken(json["refresh_token"].toString());
            qDebug() << "Emit loginSuccess(message)";
            emit loginSuccess(message);
            message = "Login successful";
        } else if (statusCode == 401) {
            // Pobieramy obiekt JSON z odpowiedzi (doc jest już sparsowany wyżej)
            QJsonObject json = doc.object();

            // Szukamy komunikatu w typowych polach (FastAPI zwykle używa "detail")
            QString serverError = json["detail"].toString();

            // Jak nie ma w "detail", sprawdźmy "message" (inny standard)
            if (serverError.isEmpty()) {
                serverError = json["message"].toString();
            }

            // WARUNEK: Jak serwer coś przysłał -> pokaż to. Jak nie -> tekst na sztywno.
            if (!serverError.isEmpty()) {
                message = "Login failed: " + serverError;
            } else {
                message = "Login failed: Incorrect username or password";
            }

            emit error(message);
        } else if (statusCode == 404) {
            // Tutaj logika z poprawek 404
            QJsonObject json = doc.object();

            if (json.isEmpty() && !responseData.isEmpty()) {
                // Nie JSON = zły adres URL
                message = QString("Error 404: Endpoint not found. Check URL: %1/api/v1/auth/login")
                              .arg(m_baseUrl);
                qDebug() << "[CRITICAL] Wrong API URL or Endpoint!";
                qDebug() << "Raw response:" << responseData;
            } else {
                // JSON = backend zgłasza błąd logiczny
                QString serverDetail = json["detail"].toString();
                if (serverDetail.isEmpty())
                    serverDetail = json["message"].toString();

                message = serverDetail.isEmpty() ? "Resource not found (404)"
                                                 : serverDetail; // Np. "User not found"
            }
            emit error(message);
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

    if (message.isEmpty() && reply->error() != QNetworkReply::NoError) {
        message = "Error: " + reply->errorString();
    }

    setResponseMessage(message);
    reply->deleteLater();
}
