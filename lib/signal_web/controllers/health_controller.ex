defmodule SignalWeb.HealthController do
  use Phoenix.Controller, formats: [:json]

  def index(conn, _params) do
    json(conn, %{
      status:  "ok",
      node:    node(),
      region:  System.get_env("FLY_REGION", "local"),
      rooms:   DynamicSupervisor.count_children(Signal.RoomSupervisor).active,
      ts:      System.system_time(:millisecond)
    })
  end
end
