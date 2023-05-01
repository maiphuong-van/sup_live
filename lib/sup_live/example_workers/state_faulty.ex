defmodule SupLive.ExampleWorkers.StateFaulty do
  use GenStateMachine

  def start_link() do
    GenStateMachine.start_link(__MODULE__, {:vietnam, nil})
  end

  def change(pid) do
    GenStateMachine.cast(pid, :flip)
  end

  def state(pid) do
    GenStateMachine.call(pid, :state)
  end

  def kill(pid, reason \\ :normal) do
    GenStateMachine.stop(pid, reason)
  end

  def handle_event(:cast, :flip, :vietnam, data) do
    {:next_state, :sweden, data}
  end

  def handle_event(:cast, :flip, :sweden, _data) do
    {:stop, :shutdown}
  end

  def handle_event({:call, from}, :state, state, data) do
    {:next_state, state, data, [{:reply, from, state}]}
  end
end
