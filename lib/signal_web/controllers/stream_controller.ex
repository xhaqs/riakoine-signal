defmodule SignalWeb.StreamController do
  use Phoenix.Controller, formats: [:json]

  @hls_base "/tmp/riakoine_hls"

  # GET /api/streams — list live streams
  def index(conn, _params) do
    streams = Signal.StreamSupervisor.list_streams()
    json(conn, %{streams: streams, count: length(streams)})
  end

  # GET /api/streams/:id — stream info
  def show(conn, %{"id" => stream_id}) do
    try do
      info = Signal.Stream.get_info(Signal.Stream.via(stream_id))
      json(conn, info)
    catch
      :exit, _ -> conn |> put_status(:not_found) |> json(%{error: "Stream not found or ended"})
    end
  end

  # DELETE /api/streams/:id — end stream (called by CF Worker on session-live-end)
  def delete(conn, %{"id" => stream_id}) do
    try do
      Signal.Stream.end_stream(stream_id)
      json(conn, %{ended: true})
    catch
      :exit, _ -> json(conn, %{ended: true, note: "stream already ended"})
    end
  end

  # GET /hls/:stream_id/index.m3u8 and /hls/:stream_id/:file
  def hls(conn, %{"stream_id" => stream_id, "file" => file}) do
    # Prevent path traversal
    safe_file = Path.basename(file)
    path = Path.join([@hls_base, stream_id, safe_file])

    if File.exists?(path) do
      content_type =
        if String.ends_with?(safe_file, ".m3u8"),
          do: "application/vnd.apple.mpegurl",
          else: "video/MP2T"

      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_content_type(content_type)
      |> send_file(200, path)
    else
      conn |> put_status(:not_found) |> json(%{error: "Segment not found"})
    end
  end
end
