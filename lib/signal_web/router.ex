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
    get    "/streams",        StreamController,  :index
    post   "/streams",        StreamController,  :create
    get    "/streams/:id",    StreamController,  :show
    delete "/streams/:id",    StreamController,  :delete
  end

  # HLS segments served outside /api — no JSON pipeline
  scope "/hls", SignalWeb do
    get "/:stream_id/:file",  StreamController,  :hls
  end
end
