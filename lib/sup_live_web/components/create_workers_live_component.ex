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
    live_supervisors =
      SupLive.SupervisionTree.get_supervision_tree()
      |> SupLive.SupervisionTree.list_supervisors(SupLive.LiveSupervisor)
      |> Enum.map(fn %{id: {:global, id}} -> id end)

    {:ok,
     assign(socket,
       form: to_form(ProcessPicker.changeset(%{})),
       worker_modules: @example_workers,
       restart_strategies: @restart_strategies,
       restart_types: @restart_types,
       amount_of_child_processes: @amount_of_child_processes,
       supervisors: [SupLive.Supervisor | live_supervisors]
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
            "restart_type" => restart,
            "supervisor" => supervisor
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

    child_supervisor = {:global, "supervisor_#{UUID.uuid1()}"}

    opts = [strategy: strategy, name: child_supervisor, max_restarts: max_restarts]

    spec =
      Supervisor.child_spec(
        {SupLive.LiveSupervisor, [%{children: children, opts: opts, name: child_supervisor}]},
        id: child_supervisor,
        type: :supervisor
      )

    supervisor =
      case supervisor do
        "Elixir.SupLive.Supervisor" -> String.to_existing_atom(supervisor)
        supervisor -> {:global, supervisor}
      end

    with {:ok, _} <- Supervisor.start_child(supervisor, spec) do
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end
end
