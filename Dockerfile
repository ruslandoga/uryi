#########
# TDLIB #
#########

# TODO ghcr.io/ruslandoga/tdlib:1.18.0-alpine-3.17.2
FROM ghcr.io/ruslandoga/tdlib-alpine:master AS tdlib

#########
# BUILD #
#########

FROM hexpm/elixir:1.14.4-erlang-25.3-alpine-3.17.2 as build

RUN apk add --no-cache --update git build-base
COPY --from=tdlib /usr/local/lib /usr/local/lib
COPY --from=tdlib /usr/local/include /usr/local/include

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

COPY c_src c_src
COPY Makefile Makefile
COPY lib lib
RUN mix compile
COPY config/runtime.exs config/

RUN mix release

#######
# APP #
#######

FROM alpine:3.18.0 AS app
RUN apk add --no-cache --update openssl zlib libgcc libstdc++ ncurses

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/uryi ./
COPY --from=tdlib /usr/local/lib/libtdjson.so.1.8.12 /usr/local/lib/libtdjson.so.1.8.12

ENV HOME=/app

CMD /app/bin/uryi start
