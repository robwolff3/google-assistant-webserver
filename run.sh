#!/bin/bash
set -e

ACCESS_TOKEN=access_token.json

if [ ! -f "/config/$ACCESS_TOKEN" ] && [ -f "/config/$CLIENT_SECRET" ]; then
    echo "[Info] Start WebUI for handling oauth2"
    python3 /oauth.py "/config/$CLIENT_SECRET" "/config/$ACCESS_TOKEN"
elif [ ! -f "/config/$ACCESS_TOKEN" ]; then
    echo "[Error] You need initialize GoogleAssistant with a client secret json!"
    exit 1
fi

exec python3 /gawebserver.py --credentials "/config/$ACCESS_TOKEN" --project-id "$PROJECT_ID" --device-model-id "$DEVICE_MODEL_ID" < /dev/null
