defmodule SignalWeb.RoomChannel do
  use Phoenix.Channel
  alias SignalWeb.Presence

  # ── Join ──────────────────────────────────────────────────────────────────

  def join("room:" <> room_id, params, socket) do
    case Signal.RoomSupervisor.ensure_room(room_id) do
      {:ok, _pid} ->
        socket = assign(socket, :room_id, room_id)
        meta = build_presence_meta(params)
        send(self(), {:after_join, meta})
        {:ok, %{peer_id: socket.assigns.peer_id}, socket}

      {:error, reason} ->
        {:error, %{reason: inspect(reason)}}
    end
  end

  # Track presence after join so the channel pid is alive
  def handle_info({:after_join, meta}, socket) do
    room_topic = "room:#{socket.assigns.room_id}"

    {:ok, _} = Presence.track(socket, socket.assigns.peer_id, meta)

    # Send current participant list to the newcomer
    push(socket, "presence_state", Presence.list(room_topic))

    # Announce arrival to everyone else
    broadcast_from!(socket, "peer_joined", %{
      peer_id: socket.assigns.peer_id,
      meta: meta
    })

    {:noreply, socket}
  end

  # ── WebRTC Signaling ──────────────────────────────────────────────────────

  # SDP Offer — relay to specific peer only
  def handle_in("offer", %{"target" => target, "sdp" => sdp}, socket) do
    broadcast_from!(socket, "offer", %{
      from:   socket.assigns.peer_id,
      target: target,
      sdp:    sdp
    })
    {:noreply, socket}
  end

  # SDP Answer
  def handle_in("answer", %{"target" => target, "sdp" => sdp}, socket) do
    broadcast_from!(socket, "answer", %{
      from:   socket.assigns.peer_id,
      target: target,
      sdp:    sdp
    })
    {:noreply, socket}
  end

  # ICE Candidate — relay to specific peer
  def handle_in("ice_candidate", %{"target" => target, "candidate" => candidate}, socket) do
    broadcast_from!(socket, "ice_candidate", %{
      from:      socket.assigns.peer_id,
      target:    target,
      candidate: candidate
    })
    {:noreply, socket}
  end

  # Room metadata (crop type, farm_id, session_type, language, etc.)
  def handle_in("update_metadata", meta, socket) when is_map(meta) do
    Signal.Room.update_metadata(socket.assigns.room_id, meta)
    broadcast!(socket, "room_metadata_updated", meta)
    {:noreply, socket}
  end

  # Media state changes (mute, camera off, screen share, etc.)
  def handle_in("media_state", state, socket) when is_map(state) do
    broadcast_from!(socket, "peer_media_state", Map.put(state, "peer_id", socket.assigns.peer_id))
    {:noreply, socket}
  end

  # Chat message within session
  def handle_in("chat_message", %{"text" => text} = msg, socket) do
    broadcast!(socket, "chat_message", %{
      peer_id:   socket.assigns.peer_id,
      text:      String.slice(text, 0, 500),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      lang:      msg["lang"] || "en"
    })
    {:noreply, socket}
  end

  # Keepalive ping
  def handle_in("ping", _, socket) do
    {:reply, {:ok, %{pong: true, ts: System.system_time(:millisecond)}}, socket}
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp build_presence_meta(params) do
    %{
      name:       params["name"]       || "Farmer",
      farmer_id:  params["farmer_id"],
      role:       params["role"]       || "participant",
      lang:       params["lang"]       || "en",
      joined_at:  DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
