defmodule Signal.Room do
  use GenServer

  # Auto-terminate room 30 min after last participant leaves
  @idle_timeout 30 * 60 * 1000

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via(room_id))
  end

  def via(room_id), do: {:via, Registry, {Signal.RoomRegistry, room_id}}

  def get_state(room_id) do
    GenServer.call(via(room_id), :get_state)
  end

  def update_metadata(room_id, meta) do
    GenServer.cast(via(room_id), {:update_metadata, meta})
  end

  @impl true
  def init(room_id) do
    {:ok, %{
      room_id: room_id,
      metadata: %{},
      created_at: DateTime.utc_now()
    }, @idle_timeout}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state, @idle_timeout}
  end

  @impl true
  def handle_cast({:update_metadata, meta}, state) do
    {:noreply, Map.update!(state, :metadata, &Map.merge(&1, meta)), @idle_timeout}
  end

  # Auto-cleanup: no participants for 30 min → room dies cleanly
  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end
