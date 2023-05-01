defmodule SupLive.ExampleWorkers.CountFaulty do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, 0)
  end

  def change(pid) do
    GenServer.cast(pid, :increase)
  end

  def state(pid) do
    GenServer.call(pid, :get_count)
  end

  def kill(pid, reason \\ :normal) do
    GenServer.stop(pid, reason)
  end

  @impl true
  def init(number) do
    {:ok, number}
  end

  @impl true
  def handle_cast(:increase, data) when data < 10 do
    {:noreply, data + 1}
  end

  def handle_cast(:increase, data) do
    {:stop, :shutdown, data}
  end

  @impl true
  def handle_call(:get_count, _from, data) do
    {:reply, data, data}
  end
end
