#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QSettings>
#include <QString>

#include "CaptchaClient.hpp"

class AuthManager : public QObject
{
    Q_OBJECT
    // Nowe property do adresu serwera
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)

    Q_PROPERTY(QString accessToken READ accessToken WRITE setAccessToken NOTIFY accessTokenChanged)
    Q_PROPERTY(
        QString refreshToken READ refreshToken WRITE setRefreshToken NOTIFY refreshTokenChanged)
    Q_PROPERTY(QString responseMessage READ responseMessage WRITE setResponseMessage NOTIFY
                   responseMessageChanged)
    Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY loggedInChanged)
    Q_PROPERTY(CaptchaClient *captcha READ captcha CONSTANT)

public:
    explicit AuthManager(QObject *parent = nullptr);
    ~AuthManager();

    QString accessToken() const { return m_accessToken; }
    QString refreshToken() const { return m_refreshToken; }
    QString responseMessage() const { return m_responseMessage; }
    bool loggedIn() const { return m_loggedIn; }
    CaptchaClient *captcha() const { return m_captchaClient; }

    // Getter dla baseUrl
    QString baseUrl() const { return m_baseUrl; }

signals:
    void accessTokenChanged();
    void refreshTokenChanged();
    void responseMessageChanged();
    void loggedInChanged();
    // Sygnał zmiany URL
    void baseUrlChanged();

    void registerSuccess(QString success);
    void loginSuccess(QString success);
    void error(QString error);

public slots:
    // Setter dla baseUrl (można wywołać z QML)
    void setBaseUrl(const QString &url);

    Q_INVOKABLE void registerUser(const QString &email,
                                  const QString &username,
                                  const QString &password,
                                  const QString &captchaAnswer);
    Q_INVOKABLE void loginUser(const QString &email, const QString &password);
    Q_INVOKABLE void logoutUser();
    Q_INVOKABLE void refreshAccessToken();
    Q_INVOKABLE void getTestData();

private:
    void setAccessToken(const QString &token);
    void setRefreshToken(const QString &token);
    void setResponseMessage(const QString &message);
    void setLoggedIn(bool loggedIn);
    void handleReply(QNetworkReply *reply, const QString &operation);
    void saveTokens();
    void loadTokens();
    void clearTokens();
    QString encryptToken(const QString &token) const;
    QString decryptToken(const QString &encryptedToken) const;

    QString m_accessToken;
    QString m_refreshToken;
    QString m_responseMessage;
    bool m_loggedIn = false;

    QNetworkAccessManager m_networkManager;
    QSettings m_settings;

    // Zmienione z const na zwykłą zmienną
    QString m_baseUrl;

    const QByteArray m_encryptionKey = "4fS3h7k4n8f5l4L9";
    CaptchaClient *m_captchaClient;
};
