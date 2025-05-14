#ifndef CAPTCHACLIENT_H
#define CAPTCHACLIENT_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonDocument>
#include <QUrl>

class CaptchaClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString captchaImageUrl READ captchaImageUrl NOTIFY captchaImageUrlChanged)
    Q_PROPERTY(QString verificationResult READ verificationResult NOTIFY verificationResultChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit CaptchaClient(QObject *parent = nullptr);

    Q_INVOKABLE void fetchCaptcha();
    Q_INVOKABLE void verifyCaptcha(const QString &answer);

    QString captchaImageUrl() const;
    QString verificationResult() const;
    bool isLoading() const;

signals:
    void captchaImageUrlChanged();
    void verificationResultChanged();
    void isLoadingChanged();

private slots:
    void onCaptchaFetched();
    void onCaptchaVerified();

private:
    QNetworkAccessManager *m_networkManager;
    QString m_captchaId;
    QString m_captchaImageUrl;
    QString m_verificationResult;
    bool m_isLoading;
    QString m_baseUrl; // Adres URL Twojego serwisu

    void setCaptchaImageUrl(const QString &url);
    void setVerificationResult(const QString &result);
    void setIsLoading(bool loading);
};

#endif // CAPTCHACLIENT_H
