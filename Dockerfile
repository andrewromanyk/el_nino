FROM elixir:1.20.1 as build

ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /build

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock config/ ./

RUN mix deps.get --only prod && \
    mix deps.compile

COPY . .

RUN mix release

FROM debian:trixie-slim

WORKDIR /release

COPY --from=build /build/_build/prod/rel/el_nino ./

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["bin/el_nino", "start"]