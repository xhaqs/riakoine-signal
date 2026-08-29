defmodule SignalWeb.IceController do
  use Phoenix.Controller, formats: [:json]

  @stun_servers [
    %{urls: "stun:stun.l.google.com:19302"},
    %{urls: "stun:stun1.l.google.com:19302"}
  ]

  # Returns time-limited TURN credentials (coturn REST API format).
  # Starlink users are behind CGNAT — TURN relay is mandatory for them.
  def index(conn, _params) do
    turn_host   = System.get_env("TURN_HOST")
    turn_secret = System.get_env("TURN_SECRET", "")
    ttl         = 86_400
    timestamp   = System.system_time(:second) + ttl
    username    = "#{timestamp}:aware"

    credential =
      :crypto.mac(:hmac, :sha, turn_secret, username)
      |> Base.encode64()

    turn_servers =
      if turn_host do
        [
          %{urls: "turn:#{turn_host}:3478",              username: username, credential: credential},
          %{urls: "turn:#{turn_host}:3478?transport=tcp", username: username, credential: credential},
          %{urls: "turns:#{turn_host}:5349",             username: username, credential: credential}
        ]
      else
        []
      end

    json(conn, %{
      iceServers: @stun_servers ++ turn_servers,
      ttl:        ttl
    })
  end
end
