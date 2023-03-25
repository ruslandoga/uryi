Uryi Gepetovich Telegramov, a self-hosted ChatGPT + Telegram secretary.

Deploy, configure, and enjoy.

Deploy to fly.io free tier:
- login to [fly.io](https://fly.io)
- create an app with `fly apps create <some-name>`
- create secrets mentioned in [fly.toml](fly.toml) `fly secrets set TD_API_ID=... TD_API_HASH=... etc.`
- `fly deploy`

Configure:

- send `/start` to your bot to start the secretary, it will go through an auth flow for your account
- add users that Uryi talks to with `/add <user_id>`

Enjoy:

- look at Uryi doing the talking
