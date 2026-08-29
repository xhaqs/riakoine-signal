import Config

config :signal, SignalWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "dev_only_secret_key_base_do_not_use_in_prod_minimum_64_chars_pad"

config :logger, level: :debug
