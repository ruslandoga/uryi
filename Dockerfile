#########
# TDLIB #
#########

FROM ghcr.io/ruslandoga/tdlib:alpine-3.17.2 AS tdlib

#########
# BUILD #
#########

FROM hexpm/elixir:1.14.3-erlang-25.3-alpine-3.17.2 as build

RUN apk add --no-cache --update git build-base
COPY --from=tdlib /usr/local/lib /usr/local/lib
COPY --from=tdlib /usr/local/include /usr/local/include

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/
RUN mix deps.get
RUN mix deps.compile

COPY lib lib
RUN mix compile
COPY config/runtime.exs config/

RUN mix release

#######
# APP #
#######

FROM alpine:3.17.2 AS app
RUN apk add --no-cache --update openssl zlib libgcc libstdc++

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/uryi ./
COPY --from=tdlib /usr/local/lib/libtdjson.so /usr/local/lib/libtdjson.so

ENV HOME=/app

CMD /app/bin/uryi start
