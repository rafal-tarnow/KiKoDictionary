#include "CaptchaClient.hpp"
#include <QDebug>

CaptchaClient::CaptchaClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_isLoading(false)
    //    , m_baseUrl("http://127.0.0.1:8001/api/v1") // ZMIEŃ JEŚLI TRZEBA
    , m_baseUrl("https://captcha.rafal-kruszyna.org:443/api/v1") // ZMIEŃ JEŚLI TRZEBA
{}

void CaptchaClient::fetchCaptcha()
{
    if (m_isLoading)
        return;
    setIsLoading(true);
    setVerificationResult(""); // Clear previous result
    setCaptchaImageUrl("");    // Clear previous image

    QNetworkRequest request(QUrl(m_baseUrl + "/captcha"));
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &CaptchaClient::onCaptchaFetched);
}

void CaptchaClient::clear()
{
    m_captchaId.clear();
    setCaptchaImageUrl("");
}

void CaptchaClient::verifyCaptcha(const QString &answer)
{
    if (m_isLoading)
        return;
    if (m_captchaId.isEmpty()) {
        setVerificationResult("Error: No CAPTCHA ID. Fetch a new CAPTCHA first.");
        return;
    }
    setIsLoading(true);

    QJsonObject jsonPayload;
    jsonPayload["id"] = m_captchaId;
    jsonPayload["answer"] = answer;

    QNetworkRequest request(QUrl(m_baseUrl + "/captcha/verify"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonPayload).toJson());
    connect(reply, &QNetworkReply::finished, this, &CaptchaClient::onCaptchaVerified);
}

QString CaptchaClient::captchaImageUrl() const
{
    return m_captchaImageUrl;
}

QString CaptchaClient::verificationResult() const
{
    return m_verificationResult;
}

bool CaptchaClient::isLoading() const
{
    return m_isLoading;
}

void CaptchaClient::onCaptchaFetched()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    setIsLoading(false);

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
        if (!jsonDoc.isNull() && jsonDoc.isObject()) {
            QJsonObject jsonObj = jsonDoc.object();
            m_captchaId = jsonObj["id"].toString();
            setCaptchaImageUrl(jsonObj["image"].toString());
            qDebug() << "CAPTCHA ID:" << m_captchaId;
            qDebug() << "Image URL (part):" << m_captchaImageUrl.left(100);
        } else {
            emit errorOccurred("Invalid response from Captcha Service");
            setVerificationResult("Error: Invalid JSON response from server.");
            qCritical() << "Failed to parse CAPTCHA JSON:" << responseData;
        }
    } else {
        emit errorOccurred("Network Error: " + reply->errorString());
        setVerificationResult("Network Error: " + reply->errorString());
        qCritical() << "Network error fetching CAPTCHA:" << reply->errorString();
    }
    reply->deleteLater();
}

void CaptchaClient::onCaptchaVerified()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    setIsLoading(false);
    m_captchaId.clear(); // CAPTCHA is consumed

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
        if (!jsonDoc.isNull() && jsonDoc.isObject()) {
            QJsonObject jsonObj = jsonDoc.object();
            bool isValid = jsonObj["is_valid"].toBool();
            setVerificationResult(isValid ? "Result: VALID" : "Result: INVALID");
        } else {
            setVerificationResult("Error: Invalid JSON response from server.");
            qCritical() << "Failed to parse verification JSON:" << responseData;
        }
    } else {
        setVerificationResult("Network Error: " + reply->errorString());
        qCritical() << "Network error verifying CAPTCHA:" << reply->errorString();
    }
    reply->deleteLater();
}

void CaptchaClient::setCaptchaImageUrl(const QString &url)
{
    if (m_captchaImageUrl != url) {
        m_captchaImageUrl = url;
        emit captchaImageUrlChanged();
    }
}

void CaptchaClient::setVerificationResult(const QString &result)
{
    if (m_verificationResult != result) {
        m_verificationResult = result;
        emit verificationResultChanged();
    }
}

void CaptchaClient::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}
