defmodule SupLiveWeb.Components.ListProcessesLiveComponent do
  use SupLiveWeb, :live_component

  @default_supervisors [
    SupLiveWeb.Telemetry,
    Phoenix.PubSub.Supervisor,
    SupLiveWeb.Endpoint
  ]

  def update(assigns, socket) do
    workers = workers(assigns.processes)

    if assigns[:change_state] == true do
      change_state(workers)
    end

    {:ok, assign(socket, workers: workers)}
  end

  defp change_state(workers) do
    workers
    |> Enum.each(fn %{pid: pid, module_name: module} ->
      module.change(pid)
    end)
  end

  defp workers(procesess) do
    procesess
    |> workers([])
    |> List.flatten()
  end

  defp workers(
         [
           %SupLive.SupervisionTree.SupervisorStruct{
             id: _supervisor_id,
             module_name: module_name,
             children: children
           }
           | res
         ],
         workers
       )
       when module_name not in @default_supervisors do
    result = [workers(children, []) | workers]

    workers(res, result)
  end

  defp workers(
         [
           %SupLive.SupervisionTree.WorkerStruct{} = worker
           | res
         ],
         workers
       ) do
    workers(res, [worker | workers])
  end

  defp workers(_, workers), do: workers
end
