Uryi Gepetovich Telegramov, a self-hosted ChatGPT + Telegram secretary.

Deploying to `fly.io`

- register on [fly.io](https://fly.io) and install `flyctl`
- create an app with `fly apps create <some-name>`
- copy [fly.toml](fly.toml)
- create secrets mentioned in [fly.toml](fly.toml) `fly secrets set TD_API_ID=... TD_API_HASH=... etc.`
- `fly deploy`
- `fly console`
- `bin/uryi remote`
- authenticate

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
