#pragma once

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QTimer>
#include <QUrl>
#include <qqml.h>

class ServerMonitor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    // Właściwość do ustawiania adresu bazowego (np. http://localhost:8000)
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    // Flaga statusu (read-only dla QML)
    Q_PROPERTY(bool isAlive READ isAlive NOTIFY isAliveChanged)
    // Częstotliwość sprawdzania w milisekundach (domyślnie np. 5000ms)
    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)

public:
    explicit ServerMonitor(QObject *parent = nullptr);

    QString serverUrl() const;
    void setServerUrl(const QString &url);

    bool isAlive() const;

    int interval() const;
    void setInterval(int ms);

    // Metoda dostępna z QML do wymuszenia sprawdzenia natychmiast
    Q_INVOKABLE void checkNow();

signals:
    void serverUrlChanged();
    void isAliveChanged();
    void intervalChanged();

private slots:
    void onReplyFinished(QNetworkReply *reply);
    void performCheck();

private:
    QNetworkAccessManager *m_manager;
    QTimer *m_timer;
    QString m_serverUrl;
    bool m_isAlive;
    int m_interval;

    void setIsAlive(bool alive);
};
