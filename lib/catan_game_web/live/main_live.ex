defmodule CatanWeb.MainLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.GameCoordinator, as: GC

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Catan.PubSub, "gc:lobbies")
    end

    socket =
      socket
      |> assign(:lobbies, GC.get_lobbies())

    {:ok, socket}
  end

  @impl true
  def handle_event("create_lobby", _params, %{assigns: %{}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_lobby, _id, _lobby}, socket) do
    {:noreply, socket |> assign(:lobbies, GC.get_lobbies())}
  end

  @impl true
  def handle_info({:delete_lobby, _id}, socket) do
    {:noreply, socket |> assign(:lobbies, GC.get_lobbies())}
  end

  @impl true
  def handle_info({:start_game, _id}, socket) do
    {:noreply, socket |> assign(:lobbies, GC.get_lobbies())}
  end

  @impl true
  def handle_info(payload, socket) do
    Logger.info("#{__MODULE__} got unhandled payload: #{inspect(payload, pretty: true)}")
    {:noreply, socket}
  end
end
