FROM hexpm/elixir:1.16.3-erlang-26.2.5-debian-bookworm-20240612-slim AS build

WORKDIR /app

RUN apt-get update -y && apt-get install -y build-essential git \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile
COPY config/runtime.exs config/

RUN mix release

# ── Runtime image ──────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS app

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

COPY --from=build --chown=nobody:root /app/_build/prod/rel/signal ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/signal", "start"]
