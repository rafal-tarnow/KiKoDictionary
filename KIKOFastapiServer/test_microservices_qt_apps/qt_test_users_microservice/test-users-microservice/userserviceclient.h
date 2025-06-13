#ifndef USERSERVICECLIENT_H
#define USERSERVICECLIENT_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QJsonObject>

class QNetworkReply;

class UserServiceClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QString captchaImageUrl READ captchaImageUrl NOTIFY captchaImageUrlChanged)
    Q_PROPERTY(QString currentUserInfo READ currentUserInfo NOTIFY currentUserInfoChanged)

public:
    explicit UserServiceClient(QObject *parent = nullptr);

    // Metody wywoływane z QML
    Q_INVOKABLE void fetchCaptcha();
    Q_INVOKABLE void registerUser(const QString &username, const QString &email, const QString &password, const QString &captchaAnswer);
    Q_INVOKABLE void loginUser(const QString &username, const QString &password);
    Q_INVOKABLE void logoutUser();
    Q_INVOKABLE void fetchCurrentUserInfo();

    // Gettery dla Q_PROPERTY
    bool isLoading() const;
    bool isLoggedIn() const;
    QString statusMessage() const;
    QString captchaImageUrl() const;
    QString currentUserInfo() const;

signals:
    void isLoadingChanged();
    void isLoggedInChanged();
    void statusMessageChanged();
    void captchaImageUrlChanged();
    void currentUserInfoChanged();

private slots:
    void onCaptchaFetched();
    void onRegistrationFinished();
    void onLoginFinished();
    void onFetchUserInfoFinished();

private:
    void setIsLoading(bool loading);
    void setIsLoggedIn(bool loggedIn);
    void setStatusMessage(const QString &message, bool isError = false);
    void setCaptchaImageUrl(const QString &url);
    void setCurrentUserInfo(const QString &info);
    void handleNetworkError(QNetworkReply *reply, const QString &context);

    QNetworkAccessManager *m_networkManager;

    // Adresy URL serwisów
    QString m_userServiceBaseUrl;
    QString m_captchaServiceBaseUrl;

    // Stan
    bool m_isLoading = false;
    bool m_isLoggedIn = false;
    QString m_statusMessage;
    QString m_currentUserInfo;

    // Dane tymczasowe
    QString m_captchaId;
    QString m_captchaImageUrl;
    QString m_authToken; // Przechowujemy token JWT
};

#endif // USERSERVICECLIENT_H
