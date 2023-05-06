defmodule SupLiveWeb.ProcessesLive do
  use SupLiveWeb, :live_view

  alias SupLiveWeb.Components.ListProcessesLiveComponent
  alias SupLiveWeb.Components.SupervisionTreeLiveComponent

  def mount(_param, _session, socket) do
    live_update(socket, "change_state")

    {:ok,
     assign(socket,
       processes: processes(),
       create_workers: false,
       list_workers: true,
       supervision_tree: false
     )}
  end

  def handle_event("create-workers-view", _, socket) do
    create_workers = socket.assigns.create_workers

    {:noreply,
     assign(socket,
       create_workers: !create_workers
     )}
  end

  def handle_event("list-workers", _, socket) do
    {:noreply,
     assign(socket,
       list_workers: true,
       supervision_tree: false
     )}
  end

  def handle_event("supervision-tree-view", _, socket) do
    {:noreply,
     assign(socket,
       list_workers: false,
       supervision_tree: true
     )}
  end

  def handle_event("kill-process", %{"id" => id}, socket) do
    case get_process(socket.assigns.processes, id) do
      %{pid: pid, module_name: module, status: :active} ->
        module.kill(pid)

      %{id: id, status: :inactive, supervisor: supervisor} ->
        Supervisor.delete_child(supervisor, id)

      _ ->
        :ok
    end

    processes = processes()

    # update_components(processes, socket) |> IO.inspect()

    {:noreply, assign(socket, :processes, processes)}
  end

  def handle_event("brutally-kill-process", %{"id" => id}, socket) do
    with %{pid: pid, module_name: module, status: :active} <-
           get_process(socket.assigns.processes, id) |> IO.inspect() do
      module.kill(pid, :brutally_kill) |> IO.inspect()
    end

    processes = processes()

    update_components(processes, socket) |> IO.inspect()
    {:noreply, assign(socket, :processes, processes)}
  end

  def handle_info("change_state", socket) do
    live_update(socket, "change_state")
    processes = processes()

    if socket.assigns.list_workers do
      send_update(ListProcessesLiveComponent,
        processes: processes,
        id: "list_workers",
        change_state: true
      )
    end

    if socket.assigns.supervision_tree do
      send_update(SupervisionTreeLiveComponent, processes: processes, id: "supervision_tree")
    end

    {:noreply, assign(socket, :processes, processes)}
  end

  defp update_components(processes, socket) do
    if socket.assigns.list_workers do
      send_update(ListProcessesLiveComponent,
        processes: processes,
        id: "list_workers"
      )
    end

    if socket.assigns.supervision_tree do
      send_update(SupervisionTreeLiveComponent, processes: processes, id: "supervision_tree")
    end
  end

  defp get_process(processes, id), do: SupLive.SupervisionTree.get_proccess(processes, id)
  defp processes(), do: SupLive.SupervisionTree.get_supervision_tree(SupLive.Supervisor)

  defp live_update(socket, message, time \\ 1000) do
    if connected?(socket),
      do: Process.send_after(self(), message, time)
  end
end
