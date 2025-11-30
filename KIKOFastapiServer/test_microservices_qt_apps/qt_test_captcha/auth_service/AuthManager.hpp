#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QSettings>

class AuthManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString accessToken READ accessToken WRITE setAccessToken NOTIFY accessTokenChanged)
    Q_PROPERTY(QString refreshToken READ refreshToken WRITE setRefreshToken NOTIFY refreshTokenChanged)
    Q_PROPERTY(QString responseMessage READ responseMessage WRITE setResponseMessage NOTIFY responseMessageChanged)
    Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY loggedInChanged)
public:
    explicit AuthManager(QObject *parent = nullptr);
    ~AuthManager();

    QString accessToken() const { return m_accessToken; }
    QString refreshToken() const { return m_refreshToken; }
    QString responseMessage() const { return m_responseMessage; }
    bool loggedIn() const { return m_loggedIn; }

signals:
    void accessTokenChanged();
    void refreshTokenChanged();
    void responseMessageChanged();
    void loggedInChanged();

public slots:
    Q_INVOKABLE void registerUser(const QString &email, const QString &username, const QString &password);
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
    const QString m_baseUrl = "http://localhost:8003";
    const QByteArray m_encryptionKey = "4fS3h7k4n8f5l4L9";
};
