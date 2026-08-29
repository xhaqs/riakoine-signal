defmodule SignalWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*",      SignalWeb.RoomChannel
  channel "broadcast:*", SignalWeb.BroadcastChannel

  @impl true
  def connect(params, socket, _connect_info) do
    peer_id = params["peer_id"] || generate_id()
    {:ok, assign(socket, :peer_id, peer_id)}
  end

  @impl true
  def id(socket), do: "peer:#{socket.assigns.peer_id}"

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
