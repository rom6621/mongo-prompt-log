import datetime
import json
import logging
import os

import azure.functions as func
from pydantic import BaseModel, Field, ValidationError
from pymongo import MongoClient

app = func.FunctionApp()


class RequestBody(BaseModel):
    ApiName: str = Field(..., min_length=0, max_length=100)
    Subscription: str = Field(..., min_length=0, max_length=100)
    PromptTokens: int = Field(..., ge=0)
    CompletionTokens: int = Field(..., ge=0)
    TotalTokens: int = Field(..., ge=0)
    PromptTimestamp: datetime.datetime
    CompletionTimestamp: datetime.datetime


@app.route(route="prompt-log", methods=[func.HttpMethod.POST], auth_level=func.AuthLevel.ANONYMOUS)
def PromptLog2Mongo(req: func.HttpRequest) -> func.HttpResponse:
    # PyMongoクライアントの初期化
    logging.info('Start init MongoDB client.')
    CONNECTION_STRING = os.environ.get("COSMOS_CONNECTION_STRING")
    MONGO_DB_NAME = os.environ.get("MONGO_DB_NAME")
    MONGO_COLLECTION_NAME = os.environ.get("MONGO_COLLECTION_NAME")
    client = MongoClient(
        CONNECTION_STRING
    )
    db = client[MONGO_DB_NAME]
    col = db[MONGO_COLLECTION_NAME]
    logging.info('Done init MongoDB Client.')

    logging.info('Start get request body.')
    try:
        req_body = RequestBody(**req.get_json())
        logging.info('Validated Request Body.')
    except (ValueError, ValidationError) as e:
        return func.HttpResponse(
            json.dumps({'error': e.errors()}),
            status_code=400,
            mimetype='application/json'
        )
    logging.info('Done get request body.')

    col.insert_one(req_body.model_dump())
    client.close()

    return func.HttpResponse(
        req_body.model_dump_json(),
        status_code=200
    )
