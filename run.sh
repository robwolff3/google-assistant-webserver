#!/bin/bash
set -e

CLIENT_JSON=client.json
CRED_JSON=cred.json

# check if a new assistant file exists
if [ -f "/config/$CLIENT_SECRETS" ]; then
    echo "[Info] Install/Update service client_secrets file"
    cp -f "/config/$CLIENT_SECRETS" "/config/$CLIENT_JSON"
fi

if [ ! -f "/config/$CRED_JSON" ] && [ -f "/config/$CLIENT_JSON" ]; then
    echo "[Info] Start WebUI for handling oauth2"
    python3 /hassio_oauth.py "/config/$CLIENT_JSON" "/config/$CRED_JSON"
elif [ ! -f "/config/$CRED_JSON" ]; then
    echo "[Error] You need initialize GoogleAssistant with a client secret json!"
    exit 1
fi

exec python3 /hassio_gassistant.py --credentials "/config/$CRED_JSON" --project-id "$PROJECT_ID" --device-model-id "$DEVICE_MODEL_ID" < /dev/null
