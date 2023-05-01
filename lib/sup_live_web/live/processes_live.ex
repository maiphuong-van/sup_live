defmodule SupLiveWeb.ProcessesLive do
  use SupLiveWeb, :live_view

  alias SupLiveWeb.Components.ListProcessesLiveComponent
  alias SupLiveWeb.Components.SupervisionTreeLiveComponent

  def mount(_param, _session, socket) do
    live_update(socket, "change_state")

    processes = SupLive.SupervisionTree.get_supervision_tree(SupLive.Supervisor)

    {:ok,
     assign(socket,
       processes: processes,
       create_workers: false,
       list_workers: false,
       supervision_tree: true
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

  def handle_info("change_state", socket) do
    live_update(socket, "change_state")
    processes = SupLive.SupervisionTree.get_supervision_tree(SupLive.Supervisor)

    if socket.assigns.list_workers do
      send_update(ListProcessesLiveComponent, processes: processes, id: "list_workers")
    end

    if socket.assigns.supervision_tree do
      send_update(SupervisionTreeLiveComponent, processes: processes, id: "supervision_tree")
    end

    {:noreply, assign(socket, :processes, processes)}
  end

  defp live_update(socket, message, time \\ 5000) do
    if connected?(socket),
      do: Process.send_after(self(), message, time)
  end
end
