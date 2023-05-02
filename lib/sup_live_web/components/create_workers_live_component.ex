defmodule SupLiveWeb.Components.CreateWorkersLiveComponent do
  use SupLiveWeb, :live_component
  alias SupLiveWeb.FormChangeset.ProcessPicker

  @example_workers [
    SupLive.ExampleWorkers.Count,
    SupLive.ExampleWorkers.CountFaulty,
    SupLive.ExampleWorkers.State,
    SupLive.ExampleWorkers.StateFaulty
  ]

  @restart_strategies [
    :one_for_one,
    :one_for_all,
    :rest_for_one,
    :simple_one_for_one
  ]

  @restart_types [
    :permanent,
    :temporary,
    :transient
  ]

  @amount_of_child_processes [1, 2, 5, 10, 100, 1000, 100_000]

  def mount(socket) do
    {:ok,
     assign(socket,
       form: to_form(ProcessPicker.changeset(%{})),
       worker_modules: @example_workers,
       restart_strategies: @restart_strategies,
       restart_types: @restart_types,
       amount_of_child_processes: @amount_of_child_processes
     )}
  end

  def handle_event(
        "start-workers",
        %{
          "process_picker" => %{
            "children" => children_count,
            "max_restarts" => max_restarts,
            "module" => module,
            "strategy" => strategy,
            "restart_type" => restart
          }
        },
        socket
      ) do
    children_count = String.to_integer(children_count)

    restart = String.to_existing_atom(restart)
    strategy = String.to_existing_atom(strategy)

    max_restarts =
      case Integer.parse(max_restarts) do
        {integer, _} when integer >= 0 -> integer
        _ -> 0
      end

    children =
      Enum.map(1..children_count, fn _ ->
        %{
          id: UUID.uuid1(),
          start: {String.to_existing_atom(module), :start_link, []},
          restart: restart
        }
      end)

    supervisor = {:global, "supervisor_#{UUID.uuid1()}"}

    opts = [strategy: strategy, name: supervisor, max_restarts: max_restarts]

    spec =
      Supervisor.child_spec(
        {SupLive.LiveSupervisor, [%{children: children, opts: opts, name: supervisor}]},
        id: supervisor,
        type: :supervisor
      )

    with {:ok, _} <- Supervisor.start_child(SupLive.Supervisor, spec) do
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end
end
