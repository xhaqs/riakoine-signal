defmodule SignalWeb.Presence do
  use Phoenix.Presence,
    otp_app: :signal,
    pubsub_server: Signal.PubSub
end
