defmodule SignalWeb.BroadcastChannel do
  use Phoenix.Channel

  # ── Broadcaster joins ─────────────────────────────────────────────────────

  def join("broadcast:" <> stream_id, params, socket) do
    role = params["role"] || "viewer"

    if role == "broadcaster" do
      meta = %{
        "title"      => params["title"] || "Live Session",
        "crop"       => params["crop"],
        "farm_id"    => params["farm_id"],
        "farmer_id"  => params["farmer_id"],
        "lang"       => params["lang"] || "en"
      }

      case Signal.StreamSupervisor.start_stream(stream_id, meta) do
        {:ok, _pid} ->
          socket = socket
            |> assign(:stream_id, stream_id)
            |> assign(:role, :broadcaster)

          {:ok, %{stream_id: stream_id, role: "broadcaster"}, socket}

        {:error, reason} ->
          {:error, %{reason: inspect(reason)}}
      end
    else
      # Viewer — subscribe to stream events
      Phoenix.PubSub.subscribe(Signal.PubSub, "stream:#{stream_id}")

      socket = socket
        |> assign(:stream_id, stream_id)
        |> assign(:role, :viewer)

      {:ok, %{stream_id: stream_id, role: "viewer"}, socket}
    end
  end

  # ── Broadcaster sends media chunk ─────────────────────────────────────────

  def handle_in("chunk", %{"data" => b64}, %{assigns: %{role: :broadcaster}} = socket) do
    case Base.decode64(b64) do
      {:ok, binary} ->
        Signal.Stream.push_chunk(socket.assigns.stream_id, binary)
        {:noreply, socket}

      :error ->
        {:reply, {:error, %{reason: "invalid base64"}}, socket}
    end
  end

  # Broadcaster ends the stream
  def handle_in("end_stream", _, %{assigns: %{role: :broadcaster}} = socket) do
    Signal.Stream.end_stream(socket.assigns.stream_id)
    {:noreply, socket}
  end

  # Stream metadata update (title, crop, etc.)
  def handle_in("update_meta", meta, %{assigns: %{role: :broadcaster}} = socket) when is_map(meta) do
    broadcast!(socket, "meta_updated", meta)
    {:noreply, socket}
  end

  # Viewer chat message
  def handle_in("chat", %{"text" => text} = msg, socket) do
    broadcast!(socket, "chat", %{
      peer_id:   socket.assigns.peer_id,
      text:      String.slice(text, 0, 300),
      lang:      msg["lang"] || "en",
      ts:        System.system_time(:millisecond)
    })
    {:noreply, socket}
  end

  # ── PubSub events → push to viewer sockets ────────────────────────────────

  def handle_info(:ended, socket) do
    push(socket, "stream_ended", %{})
    {:noreply, socket}
  end

  # Reject viewer writes to stream
  def handle_in(_, _, %{assigns: %{role: :viewer}} = socket) do
    {:reply, {:error, %{reason: "viewers are read-only"}}, socket}
  end
end
