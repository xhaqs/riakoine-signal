import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "Missing SECRET_KEY_BASE — generate with: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "riakoine-signal.fly.dev"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :signal, SignalWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
