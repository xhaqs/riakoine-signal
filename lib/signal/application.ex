defmodule Signal.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Signal.RoomRegistry},
      {Phoenix.PubSub, name: Signal.PubSub},
      SignalWeb.Presence,
      Signal.RoomSupervisor,
      SignalWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Signal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SignalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
