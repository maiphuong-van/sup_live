defmodule SupLiveWeb.Components.ListProcessesLiveComponent do
  use SupLiveWeb, :live_component

  @default_supervisors [
    SupLiveWeb.Telemetry,
    Phoenix.PubSub.Supervisor,
    SupLiveWeb.Endpoint
  ]

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    workers =
      assigns.processes
      |> workers(nil)

    # Change process state for next live update
    workers
    |> Enum.each(fn %{pid: pid, module_name: module} ->
      module.change(pid)
    end)

    {:ok, assign(socket, workers: workers)}
  end

  defp workers(procesess, supervisor_name) do
    procesess
    |> workers(supervisor_name, [])
    |> List.flatten()
  end

  defp workers(
         [
           %SupLive.SupervisionTree.SupervisorStruct{
             id: supervisor_id,
             module_name: module_name,
             children: children
           }
           | res
         ],
         supervisor_name,
         workers
       )
       when module_name not in @default_supervisors do
    result = [workers(children, supervisor_id, []) | workers]

    workers(res, supervisor_name, result)
  end

  defp workers(
         [
           %SupLive.SupervisionTree.WorkerStruct{} = worker
           | res
         ],
         supervisor_name,
         workers
       ) do
    worker = %{worker | supervisor_name: supervisor_name}

    workers(res, supervisor_name, [worker | workers])
  end

  defp workers(_, _, workers), do: workers
end
