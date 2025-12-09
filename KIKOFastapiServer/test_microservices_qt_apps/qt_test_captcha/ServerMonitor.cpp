#include "ServerMonitor.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>

ServerMonitor::ServerMonitor(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_timer(new QTimer(this))
    , m_isAlive(false)
    , m_interval(5000)
{
    connect(m_timer, &QTimer::timeout, this, &ServerMonitor::performCheck);
    connect(m_manager, &QNetworkAccessManager::finished, this, &ServerMonitor::onReplyFinished);

    m_timer->start(m_interval);
}

QString ServerMonitor::serverUrl() const
{
    return m_serverUrl;
}

void ServerMonitor::setServerUrl(const QString &url)
{
    if (m_serverUrl == url)
        return;
    m_serverUrl = url;

    // Usuń ewentualny slash na końcu, aby łatwiej budować ścieżkę
    if (m_serverUrl.endsWith('/')) {
        m_serverUrl.chop(1);
    }

    emit serverUrlChanged();
    checkNow(); // Sprawdź od razu po zmianie adresu
}

bool ServerMonitor::isAlive() const
{
    return m_isAlive;
}

int ServerMonitor::interval() const
{
    return m_interval;
}

void ServerMonitor::setInterval(int ms)
{
    if (m_interval == ms)
        return;
    m_interval = ms;
    m_timer->setInterval(m_interval);
    emit intervalChanged();
}

void ServerMonitor::checkNow()
{
    performCheck();
}

void ServerMonitor::performCheck()
{
    if (m_serverUrl.isEmpty()) {
        setIsAlive(false);
        return;
    }

    // Budowanie pełnego adresu: BASE_URL + PREFIX + ENDPOINT
    // Z Twojego kodu wynika: prefix="/health", endpoint="/live"
    QString fullPath = m_serverUrl + "/health/live";
    QUrl url(fullPath);

    if (!url.isValid()) {
        qWarning() << "Invalid URL:" << fullPath;
        setIsAlive(false);
        return;
    }

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Wysłanie zapytania GET
    m_manager->get(request);
}

void ServerMonitor::onReplyFinished(QNetworkReply *reply)
{
    bool aliveStatus = false;

    if (reply->error() == QNetworkReply::NoError) {
        // 1. Sprawdź kod HTTP (oczekujemy 200 OK z Twojego kodu FastAPI)
        int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        if (statusCode == 200) {
            // 2. Parsuj JSON, aby upewnić się, że to nasza aplikacja
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);

            if (!doc.isNull() && doc.isObject()) {
                QJsonObject obj = doc.object();
                // Sprawdzamy pole "status" z modelu Pydantic HealthCheckResponse
                if (obj["status"].toString() == "ok") {
                    aliveStatus = true;
                }
            }
        }
    } else {
        // Opcjonalnie: logowanie błędów
        // qDebug() << "Health Check Error:" << reply->errorString();
    }

    setIsAlive(aliveStatus);
    reply->deleteLater();
}

void ServerMonitor::setIsAlive(bool alive)
{
    if (m_isAlive == alive)
        return;
    m_isAlive = alive;
    emit isAliveChanged();

    if (m_isAlive) {
        qDebug() << "Server is ONLINE:" << m_serverUrl;
    } else {
        qDebug() << "Server is OFFLINE:" << m_serverUrl;
    }
}
