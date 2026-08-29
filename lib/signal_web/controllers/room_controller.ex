defmodule SignalWeb.RoomController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, params) do
    room_id = params["room_id"] || generate_id()

    case Signal.RoomSupervisor.ensure_room(room_id) do
      {:ok, _pid} ->
        meta = Map.take(params, ["crop", "farm_id", "session_type", "host_farmer_id", "lang"])
        if map_size(meta) > 0, do: Signal.Room.update_metadata(room_id, meta)

        conn
        |> put_status(:created)
        |> json(%{room_id: room_id, ws_topic: "room:#{room_id}"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: inspect(reason)})
    end
  end

  def show(conn, %{"id" => room_id}) do
    try do
      state = Signal.Room.get_state(room_id)
      presences = SignalWeb.Presence.list("room:#{room_id}")
      participant_count = map_size(presences)

      json(conn, %{
        room_id:           room_id,
        metadata:          state.metadata,
        participant_count: participant_count,
        created_at:        DateTime.to_iso8601(state.created_at)
      })
    catch
      :exit, _ ->
        conn |> put_status(:not_found) |> json(%{error: "Room not found"})
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
