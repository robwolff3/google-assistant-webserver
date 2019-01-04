# Google Assistant Webserver in a Docker container

## What is this?

This is a emulated Google Assistant with a webserver attached to take commands over HTTP packaged in a Docker container. The container consists of the Google Assistant SDK, python scripts that provide the Flask REST API / OAuth authentication and modifications that base it from the Google Assistant library.

I did not write this code, I simply pulled pieces and modified them to work together. AndBobsYourUncle wrote Google Assistant webserver Hassio add-on which this is largely based on. Chocomega provided the modifications that based it off the Google Assistant libraries.

How does this differ from AndBobsYourUncle's [Google Assistant Webserver](https://community.home-assistant.io/t/community-hass-io-add-on-google-assistant-webserver-broadcast-messages-without-interrupting-music/37274)? This project is modified, running based on the Google Assistant libraries not the Google Assistant Service which allows for additional functionality such as remote media casting (Casting Spotify) [See the table here](https://community.home-assistant.io/t/community-hass-io-add-on-google-assistant-webserver-broadcast-messages-without-interrupting-music/37274/343). However this method requires a mic and speaker audio device on the host machine.

* [AndBobsYourUncle Home Assistant forum post](https://community.home-assistant.io/t/community-hass-io-add-on-google-assistant-webserver-broadcast-messages-without-interrupting-music/37274) and [Hassio Add-on Github repository](https://github.com/AndBobsYourUncle/hassio-addons)
* [Chocomega modifications](https://community.home-assistant.io/t/community-hass-io-add-on-google-assistant-webserver-broadcast-messages-without-interrupting-music/37274/234)
* [Google Assistant Library docs](https://developers.google.com/assistant/sdk/guides/library/python/)

## Setup

* Prerequisite - Mic and speaker audio devices configured on the host machine. If you're not sure or need help you can follow [Googles Configure and Test the Audio documentation here](https://developers.google.com/assistant/sdk/guides/library/python/embed/audio?hardware=ubuntu).
1. Go the **_Configure a Developer Project and Account Settings_** page of the **_Embed the Google Assistant_** procedure in the [Library docs](https://developers.google.com/assistant/sdk/guides/library/python/embed/config-dev-project-and-account).
2. Follow the steps through to **_Register the Device Model_** and take note of the project id and the device model id.
3. **_Download OAuth 2.0 Credentials_** file, rename it to `client_secret.json` and move it to the configuration directory `/home/user/docker/config/gawebserver`.
4. In a Docker configuration below, fill out the `DEVICE_MODEL_ID` and `PROJECT_ID` environment variables with the values from previous steps. Lastly change the volume to mount your configuration directory to `/config`.

## First Run

* Start the container using Docker Run or Docker Compose. It will start listening on ports 9324 and 5000. Browse to the container on port 9324 (`http://containerip:9324`) where you will see **_Get token from google: Authentication_**. 
* Follow the URL, authenticate with Google, return the string from Google to the container web page and click connect. The page will error out and that is normal, the container is now up and running.

### Docker Run

```bash
$ docker run -d --name=gawebserver \
    --restart on-failure \
    -v /home/user/docker/config/gawebserver:/config \
    -p 9324:9324 \
    -p 5000:5000 \
    -e CLIENT_SECRET=client_secret.json \
    -e DEVICE_MODEL_ID=device_model_id \
    -e PROJECT_ID=project_id \
    --device /dev/snd:/dev/snd:rwm \
    robwolff3/ga-webserver
```

### Docker Compose

```yml
version: "3.4"
services:
  gawebserver:
    container_name: gawebserver
    image: robwolff3/ga-webserver
    restart: on-failure
    volumes:
      - /home/user/docker/config/gawebserver:/config
    ports:
      - 9324:9324
      - 5000:5000
    environment:
      - CLIENT_SECRET=client_secret.json
      - DEVICE_MODEL_ID=device_model_id
      - PROJECT_ID=project_id
    devices:
      - "/dev/snd:/dev/snd:rwm"
```

## Test it

* Test out your newly created ga-webserver by sending it a command through your web browser.
* Send a command `http://containerip:5000/command?message=Play Careless Whisper by George Michael on Kitchen Stereo` 
* Broadcast a message `http://containerip:5000/broadcast_message?message=Alexa order 500 pool noodles`

Not sure why a command isn't working? See what happened in your [Google Account Activity](https://myactivity.google.com/item?restrict=assist&embedded=1&utm_source=opa&utm_medium=er&utm_campaign=) or under **_My Activity_** in the Google Assistant App.

## Home Assistant

Here is an example how I use the ga-webserver in Home Assistant to broadcast over my Google Assistants when my dishwasher has finished.

#### configuration.yaml

```yml
notify:
  - name: ga_broadcast
    platform: rest
    resource: http://containerip:5000/broadcast_message
  - name: ga_command
    platform: rest
    resource: http://containerip:5000/command
```

#### automations.yaml

```yml
  - alias: Broadcast the dishwasher has finished
    initial_state: True
    trigger:
      - platform: state
        entity_id: input_select.dishwasher_status
        to: 'Off'
    action:
      - service: notify.ga_broadcast
        data:
          message: "The Dishwasher has finished."
```

[My Home Assistant Configuration repository](https://github.com/robwolff3/homeassistant-config).

## Troubleshooting

* Broadcast messages not working? You may need to set an address on the ga-webserver the same as the address's registered with your other Google Assistant devices. In the Google Assistant app go to **_More > Settings > Settings > Assistant_**. At the bottom select your ga-webserver and set the applicable address.

* If it was working and then all the sudden stopped then you may need to re-authenticate. Stop the container, delete the `access_token.json` file from the configuration directory, repeat the **First Run** procedure above.

* Have problems? Check the container logs: `docker logs -f gawebserver`
