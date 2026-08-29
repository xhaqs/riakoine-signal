defmodule Signal.StreamSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_stream(stream_id, meta \\ %{}) do
    case DynamicSupervisor.start_child(__MODULE__, {Signal.Stream, {stream_id, meta}}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      err -> err
    end
  end

  def list_streams do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.flat_map(fn {_, pid, _, _} ->
      try do
        [Signal.Stream.get_info(pid)]
      catch
        :exit, _ -> []
      end
    end)
  end
end
