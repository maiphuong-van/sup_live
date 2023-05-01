defmodule SupLiveWeb.IndexLive do
  use SupLiveWeb, :live_view
  alias SupLiveWeb.FormChangeset.ProcessPicker

  def mount(_param, _session, socket) do
    live_update(socket, "change_state")

    {:ok,
     assign(socket, %{
       processes: processes(),
       form: to_form(ProcessPicker.changeset(%{module_name: SupLive.ExampleWorkers.Count})),
       modules: [
         SupLive.ExampleWorkers.Count,
         SupLive.ExampleWorkers.CountFaulty,
         SupLive.ExampleWorkers.State,
         SupLive.ExampleWorkers.StateFaulty
       ]
     })}
  end

  def handle_event(
        "start-supervisor",
        %{"process_picker" => %{"module" => module, "children" => child_count}},
        socket
      ) do
    child_count = String.to_integer(child_count)

    children =
      Enum.map(1..child_count, fn _ ->
        %{
          id: UUID.uuid1(),
          start: {String.to_existing_atom(module), :start_link, []},
          restart: :transient
        }
      end)

    supervisor = {:global, "supervisor_#{UUID.uuid1()}"}

    opts = [strategy: :one_for_all, name: supervisor, max_restarts: 0]

    spec =
      Supervisor.child_spec(
        {SupLive.LiveSupervisor, [%{children: children, opts: opts, name: supervisor}]},
        id: supervisor,
        type: :supervisor
      )

    with {:ok, _} <- Supervisor.start_child(SupLive.Supervisor, spec) do
      live_update(socket, "change_state")

      {:noreply,
       assign(socket, %{
         processes: processes()
       })}
    else
      _ -> {:noreply, socket}
    end
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

    {:noreply, assign(socket, :processes, processes())}
  end

  def handle_event("brutally-kill-process", %{"id" => id}, socket) do
    with %{pid: pid, module_name: module, status: :active} <-
           get_process(socket.assigns.processes, id) do
      module.kill(pid, :brutally_kill)
    end

    {:noreply, assign(socket, :processes, processes())}
  end

  def handle_event("kill-inactive-processes", _, socket) do
    inactive_processes =
      socket.assigns.processes
      |> Enum.filter(&(&1.status == :inactive))

    for %{pid: pid, module_name: module, id: id, supervisor: supervisor} <- inactive_processes do
      if is_pid(pid) and :erlang.is_process_alive(pid) do
        module.kill(pid)
      end

      Supervisor.delete_child(supervisor, id)
    end

    {:noreply, assign(socket, :processes, processes())}
  end

  def handle_info("change_state", socket) do
    socket.assigns.processes
    |> Enum.each(fn %{pid: pid, module_name: module} ->
      module.change(pid)
    end)

    processes = processes()

    unless Enum.all?(processes, &(&1.status == :inactive)) do
      live_update(socket, "change_state")
    end

    {:noreply, assign(socket, :processes, processes)}
  end

  defp processes() do
    default_supervisors = [
      SupLiveWeb.Telemetry,
      Phoenix.PubSub.Supervisor,
      SupLiveWeb.Endpoint
    ]

    supervisors =
      SupLive.Supervisor
      |> Supervisor.which_children()
      |> Stream.filter(&(elem(&1, 2) == :supervisor))
      |> Stream.reject(&(elem(&1, 0) in default_supervisors))
      |> Enum.map(&elem(&1, 0))

    Enum.flat_map(supervisors, fn supervisor ->
      supervisor
      |> Supervisor.which_children()
      |> Enum.filter(&(elem(&1, 2) == :worker))
      |> Enum.reduce([], &parse_process(&1, supervisor, &2))
    end)
  end

  defp parse_process({id, pid, _type, [module]}, supervisor, acc) when is_pid(pid) do
    state =
      if :erlang.is_process_alive(pid) do
        %{status: :active, state: module.state(pid)}
      else
        %{status: :inactive, state: nil}
      end

    process = Map.merge(state, %{pid: pid, module_name: module, id: id, supervisor: supervisor})

    [process | acc]
  end

  defp parse_process({id, :undefined, _type, [module]}, supervisor, acc) do
    [
      %{
        pid: :undefined,
        module_name: module,
        id: id,
        status: :inactive,
        state: nil,
        supervisor: supervisor
      }
      | acc
    ]
  end

  defp parse_process(_other, _, acc) do
    acc
  end

  defp live_update(socket, message, time \\ 5000) do
    if connected?(socket),
      do: Process.send_after(self(), message, time)
  end

  defp get_process(processes, id) do
    case Enum.find(processes, &(&1.id == id)) do
      nil -> nil
      child_process -> child_process
    end
  end
end
