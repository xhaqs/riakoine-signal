defmodule Signal.Stream do
  use GenServer

  @hls_base "/tmp/riakoine_hls"
  @idle_timeout 10 * 60 * 1000

  defstruct [:stream_id, :ffmpeg_port, :hls_path, :started_at, :metadata, :broadcaster_id, :live]

  def start_link({stream_id, meta}) do
    GenServer.start_link(__MODULE__, {stream_id, meta}, name: via(stream_id))
  end

  def via(stream_id), do: {:via, Registry, {Signal.StreamRegistry, stream_id}}

  def push_chunk(stream_id, binary) do
    GenServer.cast(via(stream_id), {:chunk, binary})
  end

  def end_stream(stream_id) do
    GenServer.cast(via(stream_id), :end_stream)
  end

  def get_info(pid_or_id) do
    GenServer.call(pid_or_id, :get_info)
  end

  # ── Init ──────────────────────────────────────────────────────────────────

  @impl true
  def init({stream_id, meta}) do
    hls_path = Path.join(@hls_base, stream_id)
    File.mkdir_p!(hls_path)

    ffmpeg = System.find_executable("ffmpeg") || "/usr/bin/ffmpeg"

    # Read WebM chunks from stdin, output low-latency HLS
    port = Port.open({:spawn_executable, ffmpeg}, [
      :binary, :use_stdio, {:stderr_to_stdout, true},
      args: ~w[
        -y -re
        -i pipe:0
        -c:v libx264 -preset ultrafast -tune zerolatency -profile:v baseline -level 3.0
        -c:a aac -b:a 96k -ar 44100
        -f hls
        -hls_time 2
        -hls_list_size 6
        -hls_flags delete_segments+append_list+omit_endlist
        -hls_segment_filename #{hls_path}/seg%05d.ts
        #{hls_path}/index.m3u8
      ]
    ])

    Phoenix.PubSub.broadcast(Signal.PubSub, "streams", {:stream_started, stream_id, meta})

    {:ok, %__MODULE__{
      stream_id:    stream_id,
      ffmpeg_port:  port,
      hls_path:     hls_path,
      started_at:   DateTime.utc_now(),
      metadata:     meta,
      broadcaster_id: meta["farmer_id"],
      live:         true
    }, @idle_timeout}
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────

  @impl true
  def handle_cast({:chunk, binary}, state) do
    Port.command(state.ffmpeg_port, binary)
    {:noreply, state, @idle_timeout}
  end

  @impl true
  def handle_cast(:end_stream, state) do
    do_end(state)
    {:stop, :normal, state}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, %{
      stream_id:   state.stream_id,
      started_at:  DateTime.to_iso8601(state.started_at),
      metadata:    state.metadata,
      broadcaster_id: state.broadcaster_id,
      live:        state.live
    }, state, @idle_timeout}
  end

  @impl true
  def handle_info({port, {:data, _log}}, state) when port == state.ffmpeg_port do
    {:noreply, state, @idle_timeout}
  end

  @impl true
  def handle_info({port, {:exit_status, _}}, state) when port == state.ffmpeg_port do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    do_end(state)
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, state) do
    Phoenix.PubSub.broadcast(Signal.PubSub, "streams", {:stream_ended, state.stream_id})
    Phoenix.PubSub.broadcast(Signal.PubSub, "stream:#{state.stream_id}", :ended)
    # HLS files stay for 1h so viewers can finish watching
    spawn(fn ->
      Process.sleep(3_600_000)
      File.rm_rf(state.hls_path)
    end)
    :ok
  end

  defp do_end(state) do
    try do Port.close(state.ffmpeg_port) rescue _ -> :ok end
  end
end
