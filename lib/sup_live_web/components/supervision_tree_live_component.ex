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
         children: children
       }) do
    supervisor_data = "<div class=\"pl-8\"> #{module_name}:#{render_pid(pid)}"

    case children do
      [] ->
        supervisor_data <> "</div>"

      _ ->
        supervisor_data <> "#{render_processes(children)}" <> "</div>"
    end
  end

  defp render_process(%SupLive.SupervisionTree.WorkerStruct{
         module_name: module_name,
         pid: pid
       }) do
    "<div class=\"pl-8\"> #{module_name}:#{render_pid(pid)}</div>"
  end

  defp render_pid(pid) do
    if is_pid(pid) do
      :erlang.pid_to_list(pid)
    else
      pid
    end
  end
end
