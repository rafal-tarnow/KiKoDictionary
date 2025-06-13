#include "userserviceclient.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

UserServiceClient::UserServiceClient(QObject *parent)
    : QObject(parent),
    m_networkManager(new QNetworkAccessManager(this))
{
    // === KONFIGURACJA ===
    // Upewnij się, że porty są zgodne z tym, na czym uruchamiasz swoje serwisy
    m_userServiceBaseUrl = "http://127.0.0.1:8002/api/v1";
    m_captchaServiceBaseUrl = "http://127.0.0.1:8001/api/v1"; // Załóżmy, że captcha działa na 8001
}

// === METODY PUBLICZNE (dla QML) ===

void UserServiceClient::fetchCaptcha()
{
    if (m_isLoading) return;
    setIsLoading(true);
    setStatusMessage("Fetching CAPTCHA...");
    setCaptchaImageUrl("");

    QNetworkRequest request(QUrl(m_captchaServiceBaseUrl + "/captcha"));
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &UserServiceClient::onCaptchaFetched);
}

void UserServiceClient::registerUser(const QString &username, const QString &email, const QString &password, const QString &captchaAnswer)
{
    if (m_isLoading) return;
    if (m_captchaId.isEmpty()) {
        setStatusMessage("Error: CAPTCHA not fetched. Please get a new CAPTCHA.", true);
        return;
    }
    setIsLoading(true);
    setStatusMessage("Registering...");

    QJsonObject payload;
    payload["username"] = username;
    payload["email"] = email;
    payload["password"] = password;
    payload["captcha_id"] = m_captchaId;
    payload["captcha_answer"] = captchaAnswer;

    QNetworkRequest request(QUrl(m_userServiceBaseUrl + "/auth/register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(payload).toJson());
    connect(reply, &QNetworkReply::finished, this, &UserServiceClient::onRegistrationFinished);
}

void UserServiceClient::loginUser(const QString &username, const QString &password)
{
    if (m_isLoading) return;
    setIsLoading(true);
    setStatusMessage("Logging in...");

    // OAuth2 wymaga formatu x-www-form-urlencoded dla tego przepływu
    QUrlQuery postData;
    postData.addQueryItem("username", username);
    postData.addQueryItem("password", password);

    QNetworkRequest request(QUrl(m_userServiceBaseUrl + "/auth/login"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QNetworkReply *reply = m_networkManager->post(request, postData.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, &UserServiceClient::onLoginFinished);
}

void UserServiceClient::logoutUser()
{
    m_authToken.clear();
    setIsLoggedIn(false);
    setCurrentUserInfo("");
    setStatusMessage("Logged out successfully.");
}

void UserServiceClient::fetchCurrentUserInfo()
{
    if (m_isLoading || m_authToken.isEmpty()) return;
    setIsLoading(true);
    setStatusMessage("Fetching user info...");

    QNetworkRequest request(QUrl(m_userServiceBaseUrl + "/users/me"));
    // Dodajemy token autoryzacyjny do nagłówka
    request.setRawHeader("Authorization", ("Bearer " + m_authToken).toUtf8());

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &UserServiceClient::onFetchUserInfoFinished);
}


// === SLOTY PRYWATNE (obsługa odpowiedzi sieciowych) ===

void UserServiceClient::onCaptchaFetched()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    setIsLoading(false);

    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if(doc.isObject()) {
            QJsonObject obj = doc.object();
            m_captchaId = obj["id"].toString();
            setCaptchaImageUrl(obj["image"].toString());
            setStatusMessage("CAPTCHA loaded. Please enter the text.", false);
        } else {
            setStatusMessage("Error: Invalid CAPTCHA response.", true);
        }
    } else {
        handleNetworkError(reply, "fetching CAPTCHA");
    }
    reply->deleteLater();
}

void UserServiceClient::onRegistrationFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    setIsLoading(false);
    m_captchaId.clear(); // CAPTCHA jest zużyta

    if (reply->error() == QNetworkReply::NoError) {
        setStatusMessage("Registration successful! You can now log in.", false);
        setCaptchaImageUrl(""); // Wyczyść obrazek po udanej rejestracji
    } else {
        handleNetworkError(reply, "registration");
    }
    reply->deleteLater();
}

void UserServiceClient::onLoginFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    setIsLoading(false);

    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if(doc.isObject()) {
            QJsonObject obj = doc.object();
            m_authToken = obj["access_token"].toString();
            if (!m_authToken.isEmpty()) {
                setIsLoggedIn(true);
                setStatusMessage("Login successful!", false);
                fetchCurrentUserInfo(); // Automatycznie pobierz dane po zalogowaniu
            } else {
                setStatusMessage("Error: Login failed, no token received.", true);
            }
        }
    } else {
        handleNetworkError(reply, "login");
    }
    reply->deleteLater();
}

void UserServiceClient::onFetchUserInfoFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    setIsLoading(false);

    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        // Upiększamy JSONa do wyświetlenia
        setCurrentUserInfo(doc.toJson(QJsonDocument::Indented));
        setStatusMessage("User info refreshed.", false);
    } else {
        handleNetworkError(reply, "fetching user info");
        // Jeśli pobranie info się nie uda (np. token wygasł), wyloguj
        logoutUser();
    }
    reply->deleteLater();
}


// === METODY POMOCNICZE ===

void UserServiceClient::handleNetworkError(QNetworkReply *reply, const QString &context)
{
    QByteArray responseData = reply->readAll();
    qWarning() << "Network error on" << context << ":" << reply->errorString() << "Response:" << responseData;
    QString errorMessage = "Error on " + context + ": ";

    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    if (doc.isObject() && doc.object().contains("detail")) {
        QJsonValue detail = doc.object()["detail"];
        if (detail.isString()) {
            errorMessage += detail.toString();
        } else if (detail.isArray()) {
            // Bardziej szczegółowy błąd walidacji z FastAPI
            errorMessage += detail.toArray().first().toObject()["msg"].toString();
        }
    } else {
        errorMessage += reply->errorString();
    }
    setStatusMessage(errorMessage, true);
}


// === IMPLEMENTACJA GETTERÓW I SETTERÓW ===
// (standardowy, powtarzalny kod do obsługi właściwości QML)

bool UserServiceClient::isLoading() const { return m_isLoading; }
bool UserServiceClient::isLoggedIn() const { return m_isLoggedIn; }
QString UserServiceClient::statusMessage() const { return m_statusMessage; }
QString UserServiceClient::captchaImageUrl() const { return m_captchaImageUrl; }
QString UserServiceClient::currentUserInfo() const { return m_currentUserInfo; }

void UserServiceClient::setIsLoading(bool loading) {
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void UserServiceClient::setIsLoggedIn(bool loggedIn) {
    if (m_isLoggedIn != loggedIn) {
        m_isLoggedIn = loggedIn;
        emit isLoggedInChanged();
    }
}

void UserServiceClient::setStatusMessage(const QString &message, bool isError) {
    QString fullMessage = (isError ? "ERROR: " : "INFO: ") + message;
    if (m_statusMessage != fullMessage) {
        m_statusMessage = fullMessage;
        emit statusMessageChanged();
    }
}

void UserServiceClient::setCaptchaImageUrl(const QString &url) {
    if (m_captchaImageUrl != url) {
        m_captchaImageUrl = url;
        emit captchaImageUrlChanged();
    }
}

void UserServiceClient::setCurrentUserInfo(const QString &info) {
    if (m_currentUserInfo != info) {
        m_currentUserInfo = info;
        emit currentUserInfoChanged();
    }
}
