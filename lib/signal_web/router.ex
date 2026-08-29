defmodule SignalWeb.Router do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SignalWeb do
    pipe_through :api

    get  "/health",           HealthController,  :index
    get  "/ice-servers",      IceController,     :index
    post "/rooms",            RoomController,    :create
    get  "/rooms/:id",        RoomController,    :show
  end
end
