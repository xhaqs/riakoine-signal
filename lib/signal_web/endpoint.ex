defmodule SignalWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :signal

  socket "/socket", SignalWeb.UserSocket,
    websocket: [timeout: 45_000, compress: true],
    longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug CORSPlug,
    origin: :all,
    methods: ["GET", "POST", "OPTIONS"],
    headers: ["Authorization", "Content-Type", "Accept", "Origin", "X-Peer-ID"]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug SignalWeb.Router
end
