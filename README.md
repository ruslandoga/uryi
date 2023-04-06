Uryi Gepetovich Telegramov gives your Telegram account a multiple personality GPT disorder.

- my Uryi lives on [fly.io;](https://fly.io) config's in [fly.toml](fly.toml)

```console
$ fly secrets list
NAME          	DIGEST          	CREATED AT
ENABLED_IN    	90b0ef824c649d6e	2023-03-28T07:58:12Z
OPENAI_API_KEY	7e1ad3e2cfa4b3d2	2023-03-28T07:58:12Z
TD_API_HASH   	93724d3d63a77cf8	2023-03-28T07:58:12Z
TD_API_ID     	c2d571b41520575a	2023-03-28T07:58:12Z
```

- my Uryi authenticates with `fly ssh console` and `/app/bin/uryi rpc Uryi.login`

```console
$ fly ssh console
# /app/bin/uryi rpc Uryi.login
Please enter your phone number: +0123456789
Please enter the authentication code you received: 12345
Please enter your password: 1234
You are logged in :)
```
