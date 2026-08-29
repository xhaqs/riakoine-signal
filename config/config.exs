import Config

config :signal, SignalWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: SignalWeb.ErrorJSON], layout: false],
  pubsub_server: Signal.PubSub,
  live_view: [signing_salt: "riakoine_signal_v1"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :peer_id, :room_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
