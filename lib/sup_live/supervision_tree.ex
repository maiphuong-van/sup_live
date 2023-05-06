defmodule SupLive.SupervisionTree do
  defmodule SupervisorStruct do
    defstruct [:module_name, :id, :status, :pid, :supervisor, children: [], type: :supervisor]
  end

  defmodule WorkerStruct do
    defstruct [:module_name, :id, :status, :state, :pid, :supervisor, type: :worker]
  end

  @example_workers [
    SupLive.ExampleWorkers.Count,
    SupLive.ExampleWorkers.CountFaulty,
    SupLive.ExampleWorkers.State,
    SupLive.ExampleWorkers.StateFaulty
  ]

  def get_supervision_tree(supervisor \\ SupLive.Supervisor) do
    case supervisor do
      SupLive.Supervisor ->
        supervisor
        |> Supervisor.which_children()
        |> Enum.map(&child_process_to_struct(&1, supervisor))

      _ ->
        if :erlang.is_process_alive(supervisor) do
          supervisor
          |> Supervisor.which_children()
          |> Enum.map(&child_process_to_struct(&1, supervisor))
        else
          []
        end
    end
  end

  defp child_process_to_struct({child_id, child_pid, :supervisor, [child_module]}, supervisor) do
    data = %{
      module_name: child_module,
      id: child_id,
      status: :active,
      pid: child_pid,
      supervisor: supervisor,
      children: get_supervision_tree(child_pid)
    }

    struct(SupervisorStruct, data)
  end

  defp child_process_to_struct({child_id, child_pid, _type, child_module}, supervisor) do
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

    data =
      Map.merge(state, %{
        pid: child_pid,
        module_name: module_name,
        id: child_id,
        supervisor: supervisor
      })

    struct(WorkerStruct, data)
  end

  def get_proccess([], _id) do
    nil
  end

  def get_proccess([process | t], id) do
    case process do
      %{id: process_id} when process_id == id ->
        process

      %SupervisorStruct{children: children} ->
        case get_proccess(children, id) do
          nil -> get_proccess(t, id)
          process when is_struct(process) -> process
        end

      _ ->
        get_proccess(t, id)
    end
  end

  @doc "list all supervisors with a provided module name"
  def list_supervisors(processes, supervisor_module) do
    list_supervisors(processes, supervisor_module, [])
  end

  defp list_supervisors([], _, result), do: result

  defp list_supervisors(
         [process = %SupervisorStruct{children: children, module_name: module_name} | t],
         supervisor_module,
         result
       ) do
    result =
      if module_name == supervisor_module do
        [process | result]
      else
        result
      end

    list_supervisors(t, supervisor_module, result) ++
      list_supervisors(children, supervisor_module, [])
  end

  defp list_supervisors([_ | t], supervisor_module, result),
    do: list_supervisors(t, supervisor_module, result)
end
