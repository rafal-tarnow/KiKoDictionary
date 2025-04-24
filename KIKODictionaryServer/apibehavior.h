// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
#ifndef APIBEHAVIOR_H
#define APIBEHAVIOR_H

#include "types.h"
#include "utils.h"

#include <QtHttpServer/QHttpServer>
#include <QtConcurrent/qtconcurrentrun.h>

#include <optional>

template<typename T, typename = void>
class CrudApi
{
};

static void addCORSHeaders(QHttpServerResponse &response) {
    QHttpHeaders headers;
    headers.append("Access-Control-Allow-Origin", "*");
    //headers.append("Access-Control-Allow-Origin", "http://localhost:30000");
    headers.append("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS");
    headers.append("Access-Control-Allow-Headers", "Content-Type, Authorization, token");
    headers.append("Access-Control-Max-Age", "86400");
    response.setHeaders(headers);
}

template<typename T>
class CrudApi<T,
              std::enable_if_t<std::conjunction_v<std::is_base_of<Jsonable, T>,
                                                  std::is_base_of<Updatable, T>>>>
{
public:
    explicit CrudApi(const IdMap<T> &data, std::unique_ptr<FromJsonFactory<T>> factory)
        : data(data), factory(std::move(factory))
    {
    }

    QFuture<QHttpServerResponse> getPaginatedList(const QHttpServerRequest &request) const
    {
        using PaginatorType = Paginator<IdMap<T>>;
        std::optional<qsizetype> maybePage;
        std::optional<qsizetype> maybePerPage;
        std::optional<qint64> maybeDelay;
        if (request.query().hasQueryItem("page"))
            maybePage = request.query().queryItemValue("page").toLongLong();
        if (request.query().hasQueryItem("per_page"))
            maybePerPage = request.query().queryItemValue("per_page").toLongLong();
        if (request.query().hasQueryItem("delay"))
            maybeDelay = request.query().queryItemValue("delay").toLongLong();

        if ((maybePage && *maybePage < 1) || (maybePerPage && *maybePerPage < 1)) {
            return QtConcurrent::run([]() {
                QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
                addCORSHeaders(response); // Dodaj nagłówki CORS
                return response;
            });
        }

        PaginatorType paginator(data, maybePage ? *maybePage : PaginatorType::defaultPage,
                                maybePerPage ? *maybePerPage : PaginatorType::defaultPageSize);

        return QtConcurrent::run([paginator = std::move(paginator), maybeDelay](){
            if (maybeDelay){
                QThread::sleep(*maybeDelay);
            }
            QHttpServerResponse response = paginator.isValid() ? QHttpServerResponse(paginator.toJson()) : QHttpServerResponse(QHttpServerResponder::StatusCode::NoContent);
            addCORSHeaders(response); // Dodaj nagłówki CORS
            return response;
        });
    }

    QHttpServerResponse getItem(qint64 itemId) const
    {
        const auto item = data.find(itemId);
        QHttpServerResponse response = item != data.end() ? QHttpServerResponse(item->toJson())
                                                          : QHttpServerResponse(QHttpServerResponder::StatusCode::NotFound);
        addCORSHeaders(response);
        return response;
    }

    //! [POST return different status code example]
    QHttpServerResponse postItem(const QHttpServerRequest &request)
    {
        const std::optional<QJsonObject> json = byteArrayToJsonObject(request.body());
        if (!json){
            return QHttpServerResponse(QHttpServerResponder::StatusCode::BadRequest);
        }

        const std::optional<T> item = factory->fromJson(*json);
        if (!item){
            return QHttpServerResponse(QHttpServerResponder::StatusCode::BadRequest);
        }

        if (data.contains(item->id)){
            return QHttpServerResponse(QHttpServerResponder::StatusCode::AlreadyReported);
        }

        const auto entry = data.insert(item->id, *item);
        QHttpServerResponse response(entry->toJson(), QHttpServerResponder::StatusCode::Created);
        addCORSHeaders(response);
        return response;
    }
    //! [POST return different status code example]

    QHttpServerResponse updateItem(qint64 itemId, const QHttpServerRequest &request)
    {
        const std::optional<QJsonObject> json = byteArrayToJsonObject(request.body());
        if (!json){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        auto item = data.find(itemId);
        if (item == data.end()){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::NoContent);
            addCORSHeaders(response);
            return response;
        }
        if (!item->update(*json)){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        QHttpServerResponse response(item->toJson());
        addCORSHeaders(response);
        return response;
    }

    QHttpServerResponse updateItemFields(qint64 itemId, const QHttpServerRequest &request)
    {
        const std::optional<QJsonObject> json = byteArrayToJsonObject(request.body());
        if (!json){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        auto item = data.find(itemId);
        if (item == data.end()){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::NoContent);
            addCORSHeaders(response);
            return response;
        }
        item->updateFields(*json);

        QHttpServerResponse response(item->toJson());
        addCORSHeaders(response);
        return response;
    }

    QHttpServerResponse deleteItem(qint64 itemId) {
        QHttpServerResponse response = (!data.remove(itemId))
        ? QHttpServerResponse(QHttpServerResponder::StatusCode::NoContent)
        : QHttpServerResponse(QHttpServerResponder::StatusCode::Ok);
        addCORSHeaders(response);
        return response;
    }

private:


private:
    IdMap<T> data;
    std::unique_ptr<FromJsonFactory<T>> factory;
};

class SessionApi
{
public:
    explicit SessionApi(const IdMap<SessionEntry> &sessions,
                        std::unique_ptr<FromJsonFactory<SessionEntry>> factory)
        : sessions(sessions), factory(std::move(factory))
    {
    }

    QHttpServerResponse registerSession(const QHttpServerRequest &request)
    {
        const auto json = byteArrayToJsonObject(request.body());
        if (!json){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }
        const auto item = factory->fromJson(*json);
        if (!item){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        const auto session = sessions.insert(item->id, *item);
        session->startSession();
        QHttpServerResponse response(session->toJson());
        addCORSHeaders(response);
        return response;
    }

    QHttpServerResponse login(const QHttpServerRequest &request)
    {
        qDebug() << __PRETTY_FUNCTION__;
        const auto json = byteArrayToJsonObject(request.body());

        if (!json || !json->contains("email") || !json->contains("password")){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        auto maybeSession = std::find_if(
            sessions.begin(), sessions.end(),
            [email = json->value("email").toString(),
             password = json->value("password").toString()](const auto &it) {
                return it.password == password && it.email == email;
            });
        if (maybeSession == sessions.end()) {
            QHttpServerResponse response(QHttpServerResponder::StatusCode::NotFound);
            addCORSHeaders(response);
            return response;
        }
        maybeSession->startSession();
        QHttpServerResponse response(maybeSession->toJson());
        addCORSHeaders(response);
        return response;
    }

    QHttpServerResponse logout(const QHttpServerRequest &request)
    {
        const auto maybeToken = getTokenFromRequest(request);
        if (!maybeToken){
            QHttpServerResponse response(QHttpServerResponder::StatusCode::BadRequest);
            addCORSHeaders(response);
            return response;
        }

        auto maybeSession = std::find(sessions.begin(), sessions.end(), *maybeToken);
        if (maybeSession != sessions.end())
            maybeSession->endSession();
        QHttpServerResponse response(QHttpServerResponder::StatusCode::Ok);
        addCORSHeaders(response);
        return response;
    }

    bool authorize(const QHttpServerRequest &request) const
    {
        const auto maybeToken = getTokenFromRequest(request);
        if (maybeToken) {
            const auto maybeSession = std::find(sessions.begin(), sessions.end(), *maybeToken);
            return maybeSession != sessions.end() && *maybeSession == *maybeToken;
        }
        return false;
    }

private:
    IdMap<SessionEntry> sessions;
    std::unique_ptr<FromJsonFactory<SessionEntry>> factory;
};

#endif // APIBEHAVIOR_H
