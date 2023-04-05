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

- the way I authenticate is `fly console` + `bin/uryi remote` and

```elixir
iex> Uryi.auth_state()
%{
  "@client_id" => 1,
  "@type" => "updateAuthorizationState",
  "authorization_state" => %{"@type" => "authorizationStateWaitPhoneNumber"}
}

iex> Uryi.auth_phone("+0123456789")
%{"@client_id" => 1, "@extra" => -576460752303423355, "@type" => "ok"}

iex> Uryi.auth_state()
%{
  "@client_id" => 1,
  "@type" => "updateAuthorizationState",
  "authorization_state" => %{
    "@type" => "authorizationStateWaitCode",
    "code_info" => %{
      "@type" => "authenticationCodeInfo",
      "phone_number" => "+0123456789",
      "timeout" => 0,
      "type" => %{
        "@type" => "authenticationCodeTypeTelegramMessage",
        "length" => 5
      }
    }
  }
}

iex> Uryi.auth_code("36991")
%{"@client_id" => 1, "@extra" => -576460752303422687, "@type" => "ok"}

iex> Uryi.auth_state()
%{
  "@client_id" => 1,
  "@type" => "updateAuthorizationState",
  "authorization_state" => %{
    "@type" => "authorizationStateWaitPassword",
    "has_passport_data" => false,
    "has_recovery_email_address" => true,
    "password_hint" => "",
    "recovery_email_address_pattern" => ""
  }
}

iex> Uryi.auth_password("password")
%{"@client_id" => 1, "@extra" => -576460752303422655, "@type" => "ok"}

iex> Uryi.auth_state()
%{
  "@client_id" => 1,
  "@type" => "updateAuthorizationState",
  "authorization_state" => %{"@type" => "authorizationStateReady"}
}
```
