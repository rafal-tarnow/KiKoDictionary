#pragma once

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QQmlEngine>
#include <QString>

class ApiClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit ApiClient(QObject *parent = nullptr);

    Q_INVOKABLE void login(const QString &username, const QString &password);
    void fetchProtectedData();

private slots:
    void onLoginFinished(QNetworkReply *reply);
    void onDataFetched(QNetworkReply *reply);

private:
    QString hostAddress = "https://dev-auth.rafal-kruszyna.org";
    QNetworkAccessManager *m_networkManager;
    QString m_jwtToken; // Zmienna przechowująca token
};
