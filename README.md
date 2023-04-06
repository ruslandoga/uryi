Uryi Gepetovich Telegramov, a self-hosted ChatGPT + Telegram secretary.

Uryi lives on [fly.io:](https://fly.io)

- my current config's in [fly.toml](fly.toml)
- my secrets are (can be set with `fly secrets set TD_API_ID=... TD_API_HASH=... etc.`)

```console
$ fly secrets list
NAME          	DIGEST          	CREATED AT
ENABLED_IN    	90b0ef824c649d6e	2023-03-28T07:58:12Z
OPENAI_API_KEY	7e1ad3e2cfa4b3d2	2023-03-28T07:58:12Z
TD_API_HASH   	93724d3d63a77cf8	2023-03-28T07:58:12Z
TD_API_ID     	c2d571b41520575a	2023-03-28T07:58:12Z
```

- the way I authenticate is `fly ssh console` + `/app/bin/uryi rpc Uryi.login` which starts the auth flow

```
Please enter your phone number: +0123456789
Please enter the authentication code you received: 12345
Please enter your password: 1234
You are logged in :)
```
