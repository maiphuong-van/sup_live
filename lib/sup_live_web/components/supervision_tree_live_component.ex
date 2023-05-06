defmodule SupLiveWeb.Components.SupervisionTreeLiveComponent do
  use SupLiveWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="supervision-tree p-4">
      <%= raw(render_processes(assigns.processes)) %>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp render_processes(processes) do
    Enum.map(processes, &render_process(&1))
  end

  defp render_process(%SupLive.SupervisionTree.SupervisorStruct{
         module_name: module_name,
         pid: pid,
         id: id,
         children: children
       }) do
    id =
      case id do
        {_, id} -> id
        id -> id
      end

    supervisor_data = "<p>#{module_name}:#{id} - #{render_pid(pid)}</p>"

    case children do
      [] ->
        supervisor_data

      _ ->
        supervisor_data <> "<div class=\"pl-8\"> #{render_processes(children)} </div>"
    end
  end

  defp render_process(%SupLive.SupervisionTree.WorkerStruct{
         module_name: module_name,
         pid: pid,
         status: status
       }) do
    colour =
      case status do
        :active -> "lime-500"
        _ -> "neutral-500"
      end

    "<p class=\"text-#{colour}\">#{module_name}:#{render_pid(pid)}<p>"
  end

  defp render_pid(pid) do
    if is_pid(pid) do
      :erlang.pid_to_list(pid)
    else
      pid
    end
  end
end
