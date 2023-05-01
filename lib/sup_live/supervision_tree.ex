defmodule SupLive.SupervisionTree do
  defmodule SupervisorStruct do
    defstruct [:module_name, :id, :status, :pid, children: [], type: :supervisor]
  end

  defmodule WorkerStruct do
    defstruct [:module_name, :id, :status, :state, :pid, :supervisor_name, type: :worker]
  end

  @example_workers [
    SupLive.ExampleWorkers.Count,
    SupLive.ExampleWorkers.CountFaulty,
    SupLive.ExampleWorkers.State,
    SupLive.ExampleWorkers.StateFaulty
  ]

  def get_supervision_tree(supervisor \\ SupLive.Supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.map(&child_process_to_struct/1)
  end

  defp child_process_to_struct({child_id, child_pid, :supervisor, [child_module]}) do
    data = %{
      module_name: child_module,
      id: child_id,
      status: :active,
      pid: child_pid,
      children: get_supervision_tree(child_pid)
    }

    struct(SupervisorStruct, data)
  end

  defp child_process_to_struct({child_id, child_pid, _type, child_module}) do
    module_name =
      case child_module do
        [] -> nil
        [module_name] -> module_name
      end

    state =
      cond do
        child_pid == :undefined ->
          %{status: :inactive}

        :erlang.is_process_alive(child_pid) == false ->
          %{status: :inactive}

        module_name in @example_workers ->
          %{status: :active, state: module_name.state(child_pid)}

        true ->
          %{status: :active}
      end

    data = Map.merge(state, %{pid: child_pid, module_name: module_name, id: child_id})

    struct(WorkerStruct, data)
  end
end
