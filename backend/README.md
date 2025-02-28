<p align="center">
  <a href="https://github.com/gozargah/vanish" target="_blank" rel="noopener noreferrer">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Gozargah/vanish-docs/raw/master/screenshots/logo-dark.png">
      <img width="160" height="160" src="https://github.com/Gozargah/vanish-docs/raw/master/screenshots/logo-light.png">
    </picture>
  </a>
</p>

<h1 align="center"/>vanish</h1>

<p align="center">
    Unified GUI Censorship Resistant Solution Powered by <a href="https://github.com/XTLS/Xray-core">Xray</a>
</p>

<br/>
<p align="center">
    <a href="#">
        <img src="https://img.shields.io/github/actions/workflow/status/gozargah/vanish/build.yml?style=flat-square" />
    </a>
    <a href="https://hub.docker.com/r/gozargah/vanish" target="_blank">
        <img src="https://img.shields.io/docker/pulls/gozargah/vanish?style=flat-square&logo=docker" />
    </a>
    <a href="#">
        <img src="https://img.shields.io/github/license/gozargah/vanish?style=flat-square" />
    </a>
    <a href="https://t.me/gozargah_vanish" target="_blank">
        <img src="https://img.shields.io/badge/telegram-group-blue?style=flat-square&logo=telegram" />
    </a>
    <a href="#">
        <img src="https://img.shields.io/badge/twitter-commiunity-blue?style=flat-square&logo=twitter" />
    </a>
    <a href="#">
        <img src="https://img.shields.io/github/stars/gozargah/vanish?style=social" />
    </a>
</p>

<p align="center">
 <a href="./README.md">
 English
 </a>
 /
  <a href="./README-ru.md">
 Русский
 </a>
</p>

<p align="center">
  <a href="https://github.com/gozargah/vanish" target="_blank" rel="noopener noreferrer" >
    <img src="https://github.com/Gozargah/vanish-docs/raw/master/screenshots/preview.png" alt="vanish screenshots" width="600" height="auto">
  </a>
</p>

## Table of Contents

- [Overview](#overview)
  - [Why using vanish?](#why-using-vanish)
    - [Features](#features)
- [Installation guide](#installation-guide)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [API](#api)
- [Backup](#backup)
- [Telegram Bot](#telegram-bot)
- [vanish CLI](#vanish-cli)
- [vanish Node](#vanish-node)
- [Webhook notifications](#webhook-notifications)
- [Donation](#donation)
- [License](#license)
- [Contributors](#contributors)

# Overview

vanish (the Persian word for "border guard" - pronounced /mærz'ban/) is a proxy management tool that provides a simple and easy-to-use user interface for managing hundreds of proxy accounts powered by [Xray-core](https://github.com/XTLS/Xray-core) and built using Python and Reactjs.

## Why using vanish?

vanish is user-friendly, feature-rich and reliable. It lets you to create different proxies for your users without any complicated configuration. Using its built-in web UI, you are able to monitor, modify and limit users.

### Features

- Built-in **Web UI**
- Fully **REST API** backend
- [**Multiple Nodes**](#vanish-node) support (for infrastructure distribution & scalability)
- Supports protocols **Vmess**, **VLESS**, **Trojan** and **Shadowsocks**
- **Multi-protocol** for a single user
- **Multi-user** on a single inbound
- **Multi-inbound** on a **single port** (fallbacks support)
- **Traffic** and **expiry date** limitations
- **Periodic** traffic limit (e.g. daily, weekly, etc.)
- **Subscription link** compatible with **V2ray** _(such as V2RayNG, SingBox, Nekoray, etc.)_, **Clash** and **ClashMeta**
- Automated **Share link** and **QRcode** generator
- System monitoring and **traffic statistics**
- Customizable xray configuration
- **TLS** and **REALITY** support
- Integrated **Telegram Bot**
- Integrated **Command Line Interface (CLI)**
- **Multi-language**
- **Multi-admin** support (WIP)

# Installation guide

Run the following command to install vanish with SQLite database:

```bash
sudo bash -c "$(curl -sL https://github.com/Gozargah/vanish-scripts/raw/master/vanish.sh)" @ install
```

Run the following command to install vanish with MySQL database:

```bash
sudo bash -c "$(curl -sL https://github.com/Gozargah/vanish-scripts/raw/master/vanish.sh)" @ install --database mysql
```

Run the following command to install vanish with MariaDB database:
```bash
sudo bash -c "$(curl -sL https://github.com/Gozargah/vanish-scripts/raw/master/vanish.sh)" @ install --database mariadb
```

Once the installation is complete:

- You will see the logs that you can stop watching them by closing the terminal or pressing `Ctrl+C`
- The vanish files will be located at `/opt/vanish`
- The configuration file can be found at `/opt/vanish/.env` (refer to [configurations](#configuration) section to see variables)
- The data files will be placed at `var/lib/vanish`
- For security reasons, the vanish dashboard is not accessible via IP address. Therefore, you must [obtain SSL certificate](https://gozargah.github.io/vanish/en/examples/issue-ssl-certificate) and access your vanish dashboard by opening a web browser and navigating to `https://YOUR_DOMAIN:8000/dashboard/` (replace YOUR_DOMAIN with your actual domain)
- You can also use SSH port forwarding to access the vanish dashboard locally without a domain. Replace `user@serverip` with your actual SSH username and server IP and Run the command below:

```bash
ssh -L 8000:localhost:8000 user@serverip
```

Finally, you can enter the following link in your browser to access your vanish dashboard:

http://localhost:8000/dashboard/

You will lose access to the dashboard as soon as you close the SSH terminal. Therefore, this method is recommended only for testing purposes.

Next, you need to create a sudo admin for logging into the vanish dashboard by the following command

```bash
vanish cli admin create --sudo
```

That's it! You can login to your dashboard using these credentials

To see the help message of the vanish script, run the following command

```bash
vanish --help
```

If you are eager to run the project using the source code, check the section below
<details markdown="1">
<summary><h3>Manual install (advanced)</h3></summary>

Install xray on your machine

You can install it using [Xray-install](https://github.com/XTLS/Xray-install)

```bash
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
```

Clone this project and install the dependencies (you need Python >= 3.8)

```bash
git clone https://github.com/Gozargah/vanish.git
cd vanish
wget -qO- https://bootstrap.pypa.io/get-pip.py | python3 -
python3 -m pip install -r requirements.txt
```

Alternatively, to have an isolated environment you can use [Python Virtualenv](https://pypi.org/project/virtualenv/)

Then run the following command to run the database migration scripts

```bash
alembic upgrade head
```

If you want to use `vanish-cli`, you should link it to a file in your `$PATH`, make it executable, and install the auto-completion:

```bash
sudo ln -s $(pwd)/vanish-cli.py /usr/bin/vanish-cli
sudo chmod +x /usr/bin/vanish-cli
vanish-cli completion install
```

Now it's time to configuration

Make a copy of `.env.example` file, take a look and edit it using a text editor like `nano`.

You probably like to modify the admin credentials.

```bash
cp .env.example .env
nano .env
```

> Check [configurations](#configuration) section for more information

Eventually, launch the application using command below

```bash
python3 main.py
```

To launch with linux systemctl (copy vanish.service file to `var/lib/vanish/vanish.service`)

```
systemctl enable var/lib/vanish/vanish.service
systemctl start vanish
```

To use with nginx

```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name  example.com;

    ssl_certificate      /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/example.com/privkey.pem;

    location ~* /(dashboard|statics|sub|api|docs|redoc|openapi.json) {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # xray-core ws-path: /
    # client ws-path: /vanish/me/2087
    #
    # All traffic is proxed through port 443, and send to the xray port(2087, 2088 etc.).
    # The '/vanish' in location regex path can changed any characters by yourself.
    #
    # /${path}/${username}/${xray-port}
    location ~* /vanish/.+/(.+)$ {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$1/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

or

```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name  vanish.example.com;

    ssl_certificate      /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

By default the app will be run on `http://localhost:8000/dashboard`. You can configure it using changing the `UVICORN_HOST` and `UVICORN_PORT` environment variables.
</details>

# Configuration

> You can set settings below using environment variables or placing them in `.env` file.

| Variable                                 | Description                                                                                                              |
| ---------------------------------------- |--------------------------------------------------------------------------------------------------------------------------|
| SUDO_USERNAME                            | Superuser's username                                                                                                     |
| SUDO_PASSWORD                            | Superuser's password                                                                                                     |
| SQLALCHEMY_DATABASE_URL                  | Database URL ([SQLAlchemy's docs](https://docs.sqlalchemy.org/en/20/core/engines.html#database-urls))                    |
| UVICORN_HOST                             | Bind application to this host (default: `0.0.0.0`)                                                                       |
| UVICORN_PORT                             | Bind application to this port (default: `8000`)                                                                          |
| UVICORN_UDS                              | Bind application to a UNIX domain socket                                                                                 |
| UVICORN_SSL_CERTFILE                     | SSL certificate file to have application on https                                                                        |
| UVICORN_SSL_KEYFILE                      | SSL key file to have application on https                                                                                |
| UVICORN_SSL_CA_TYPE                      | Type of authority SSL certificate. Use `private` for testing self-signed CA (default: `public`)                          |
| XRAY_JSON                                | Path of Xray's json config file (default: `xray_config.json`)                                                            |
| XRAY_EXECUTABLE_PATH                     | Path of Xray binary (default: `/usr/local/bin/xray`)                                                                     |
| XRAY_ASSETS_PATH                         | Path of Xray assets (default: `/usr/local/share/xray`)                                                                   |
| XRAY_SUBSCRIPTION_URL_PREFIX             | Prefix of subscription URLs                                                                                              |
| XRAY_FALLBACKS_INBOUND_TAG               | Tag of the inbound that includes fallbacks, needed in the case you're using fallbacks                                    |
| XRAY_EXCLUDE_INBOUND_TAGS                | Tags of the inbounds that shouldn't be managed and included in links by application                                      |
| CUSTOM_TEMPLATES_DIRECTORY               | Customized templates directory (default: `app/templates`)                                                                |
| CLASH_SUBSCRIPTION_TEMPLATE              | The template that will be used for generating clash configs (default: `clash/default.yml`)                               |
| SUBSCRIPTION_PAGE_TEMPLATE               | The template used for generating subscription info page (default: `subscription/index.html`)                             |
| HOME_PAGE_TEMPLATE                       | Decoy page template (default: `home/index.html`)                                                                         |
| TELEGRAM_API_TOKEN                       | Telegram bot API token  (get token from [@botfather](https://t.me/botfather))                                            |
| TELEGRAM_ADMIN_ID                        | Numeric Telegram ID of admin (use [@userinfobot](https://t.me/userinfobot) to found your ID)                             |
| TELEGRAM_PROXY_URL                       | Run Telegram Bot over proxy                                                                                              |
| JWT_ACCESS_TOKEN_EXPIRE_MINUTES          | Expire time for the Access Tokens in minutes, `0` considered as infinite (default: `1440`)                               |
| DOCS                                     | Whether API documents should be available on `/docs` and `/redoc` or not (default: `False`)                              |
| DEBUG                                    | Debug mode for development (default: `False`)                                                                            |
| WEBHOOK_ADDRESS                          | Webhook address to send notifications to. Webhook notifications will be sent if this value was set.                      |
| WEBHOOK_SECRET                           | Webhook secret will be sent with each request as `x-webhook-secret` in the header (default: `None`)                      |
| NUMBER_OF_RECURRENT_NOTIFICATIONS        | How many times to retry if an error detected in sending a notification (default: `3`)                                    |
| RECURRENT_NOTIFICATIONS_TIMEOUT          | Timeout between each retry if an error detected in sending a notification in seconds (default: `180`)                    |
| NOTIFY_REACHED_USAGE_PERCENT             | At which percentage of usage to send the warning notification (default: `80`)                                            |
| NOTIFY_DAYS_LEFT                         | When to send warning notifaction about expiration (default: `3`)                                                         |
| USERS_AUTODELETE_DAYS                    | Delete expired (and optionally limited users) after this many days (Negative values disable this feature, default: `-1`) |
| USER_AUTODELETE_INCLUDE_LIMITED_ACCOUNTS | Whether to include limited accounts in the auto-delete feature (default: `False`)                                        |
| USE_CUSTOM_JSON_DEFAULT                  | Enable custom JSON config for ALL supported clients (default: `False`)                                                   |
| USE_CUSTOM_JSON_FOR_V2RAYNG              | Enable custom JSON config only for V2rayNG (default: `False`)                                                            |
| USE_CUSTOM_JSON_FOR_STREISAND            | Enable custom JSON config only for Streisand (default: `False`)                                                          |
| USE_CUSTOM_JSON_FOR_V2RAYN               | Enable custom JSON config only for V2rayN (default: `False`)                                                             |


# Documentation

The [vanish Documentation](https://gozargah.github.io/vanish) provides all the essential guides to get you started, available in three languages: Farsi, English, and Russian. This documentation requires significant effort to cover all aspects of the project comprehensively. We welcome and appreciate your contributions to help us improve it. You can contribute on this [GitHub repository](https://github.com/Gozargah/gozargah.github.io).


# API

vanish provides a REST API that enables developers to interact with vanish services programmatically. To view the API documentation in Swagger UI or ReDoc, set the configuration variable `DOCS=True` and navigate to the `/docs` and `/redoc`.


# Backup

It's always a good idea to backup your vanish files regularly to prevent data loss in case of system failures or accidental deletion. Here are the steps to backup vanish:

1. By default, all vanish important files are saved in `var/lib/vanish` (Docker versions). Copy the entire `var/lib/vanish` directory to a backup location of your choice, such as an external hard drive or cloud storage.
2. Additionally, make sure to backup your env file, which contains your configuration variables, and also, your Xray config file. If you installed vanish using vanish-scripts (recommended installation approach), the env and other configurations should be inside `/opt/vanish/` directory.

vanish's backup service efficiently zips all necessary files and sends them to your specified Telegram bot. It supports SQLite, MySQL, and MariaDB databases. One of its key features is automation, allowing you to schedule backups every hour. There are no limitations concerning Telegram's upload limits for bots; if a file exceeds the limit, it will be split and sent in multiple parts. Additionally, you can initiate an immediate backup at any time.

Install the Latest Version of vanish Command:
```bash
sudo bash -c "$(curl -sL https://github.com/Gozargah/vanish-scripts/raw/master/vanish.sh)" @ install-script
```

Setup the Backup Service:
```bash
vanish backup-service
```

Get an Immediate Backup:
```bash
vanish backup
```

By following these steps, you can ensure that you have a backup of all your vanish files and data, as well as your configuration variables and Xray configuration, in case you need to restore them in the future. Remember to update your backups regularly to keep them up-to-date.

# Telegram Bot

vanish comes with an integrated Telegram bot that can handle server management, user creation and removal, and send notifications. This bot can be easily enabled by following a few simple steps, and it provides a convenient way to interact with vanish without having to log in to the server every time.

To enable Telegram Bot:

1. set `TELEGRAM_API_TOKEN` to your bot's API Token
2. set `TELEGRAM_ADMIN_ID` to your Telegram account's numeric ID, you can get your ID from [@userinfobot](https://t.me/userinfobot)

# vanish CLI

vanish comes with an integrated CLI named `vanish-cli` which allows administrators to have direct interaction with it.

If you've installed vanish using easy install script, you can access the cli commands by running

```bash
vanish cli [OPTIONS] COMMAND [ARGS]...
```

For more information, You can read [vanish CLI's documentation](./cli/README.md).

# vanish Node

The vanish project introduces the [vanish-node](https://github.com/gozargah/vanish-node), which revolutionizes infrastructure distribution. With vanish-node, you can distribute your infrastructure across multiple locations, unlocking benefits such as redundancy, high availability, scalability, flexibility. vanish-node empowers users to connect to different servers, offering them the flexibility to choose and connect to multiple servers instead of being limited to only one server.
For more detailed information and installation instructions, please refer to the [vanish-node official documentation](https://github.com/gozargah/vanish-node)

# Webhook notifications

You can set a webhook address and vanish will send the notifications to that address.

the requests will be sent as a post request to the adress provided by `WEBHOOK_ADDRESS` with `WEBHOOK_SECRET` as `x-webhook-secret` in the headers.

Example request sent from vanish:

```
Headers:
Host: 0.0.0.0:9000
User-Agent: python-requests/2.28.1
Accept-Encoding: gzip, deflate
Accept: */*
Connection: keep-alive
x-webhook-secret: something-very-very-secret
Content-Length: 107
Content-Type: application/json



Body:
{"username": "vanish_test_user", "action": "user_updated", "enqueued_at": 1680506457.636369, "tries": 0}
```

Different action typs are: `user_created`, `user_updated`, `user_deleted`, `user_limited`, `user_expired`, `user_disabled`, `user_enabled`

# Donation

If you found vanish useful and would like to support its development, you can make a donation in one of the following crypto networks:

- TRON network (TRC20): `TX8kJoDcowQPBFTYHAJR36GyoUKP1Xwzkb`
- ETH, BNB, MATIC network (ERC20, BEP20): `0xFdc9ad32454FA4fc4733270FCc12ddBFb68b83F7`
- Bitcoin network: `bc1qpys2nefgsjjgae3g3gqy9crsv3h3rm96tlkz0v`
- Dogecoin network: `DJAocBAu8y6LwhDKUktLAyzV8xyoFeHH6R`
- TON network: `EQAVf-7hAXHlF-jmrKE44oBwN7HGQFVBLAtrOsev5K4qR4P8`

Thank you for your support!

# License

Made in [Unknown!] and Published under [AGPL-3.0](./LICENSE).

# Contributors

We ❤️‍🔥 contributors! If you'd like to contribute, please check out our [Contributing Guidelines](CONTRIBUTING.md) and feel free to submit a pull request or open an issue. We also welcome you to join our [Telegram](https://t.me/gozargah_vanish) group for either support or contributing guidance.

Check [open issues](https://github.com/gozargah/vanish/issues) to help the progress of this project.

<p align="center">
Thanks to the all contributors who have helped improve vanish:
</p>
<p align="center">
<a href="https://github.com/Gozargah/vanish/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Gozargah/vanish" />
</a>
</p>
<p align="center">
  Made with <a rel="noopener noreferrer" target="_blank" href="https://contrib.rocks">contrib.rocks</a>
</p>
