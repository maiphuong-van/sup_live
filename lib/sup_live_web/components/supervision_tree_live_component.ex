defmodule SupLiveWeb.Components.SupervisionTreeLiveComponent do
  use SupLiveWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="supervision-tree" dir="ltr">
      <ul class="list-disc list-inside">
        <%= raw(render_processes(assigns.processes)) %>
      </ul>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
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
    supervisor_data = "<li class\"ps-8\"> #{module_name}:#{render_pid(pid)} </li>"

    case children do
      [] ->
        supervisor_data

      _ ->
        supervisor_data <>
          "<ul class=\"list-disc list-inside\">
          #{render_processes(children)} </ul>"
    end
  end

  defp render_process(%SupLive.SupervisionTree.WorkerStruct{
         module_name: module_name,
         pid: pid
       }) do
    "<li class\"ps-8\"> #{module_name}:#{render_pid(pid)}</li>"
  end

  defp render_pid(pid) do
    if is_pid(pid) do
      :erlang.pid_to_list(pid)
    else
      pid
    end
  end
end
