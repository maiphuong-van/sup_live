defmodule SupLive.LiveSupervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link([init_arg]) do
    Supervisor.start_link(__MODULE__, init_arg, name: init_arg.name)
  end

  @impl true
  def init(%{children: children, opts: opts}) do
    Supervisor.init(children, opts)
  end
end
