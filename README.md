Uryi Gepetovich Telegramov, a self-hosted ChatGPT + Telegram secretary.

Deploy, configure, and enjoy.

Deploy:

- replace `CHAT_ID` and `BOT_TOKEN` in [fly.toml](fly.toml), and you can deploy Uryi to [fly.io](https://fly.io) with a signle command: `fly deploy`

Configure:

- send `/start` to your bot to start the secretary, it will go through an auth flow for your account
- add users that Uryi talks to with `/add <user_id>`

Enjoy:

- look at Uryi doing the talking
