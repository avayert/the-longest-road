defmodule CatanWeb.MainLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.GameCoordinator, as: GC

  @impl true
  def mount(_params, session, socket) do
    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Catan.PubSub, "gc:lobbies")
        socket
      else
        socket
        # initial connect, pre ws connection
      end
      |> assign(:lobbies, GC.get_lobbies())
      |> assign_new(:player_profile, fn -> session["player_profile"] end)

    {:ok, socket}
  end

  @impl true
  def handle_event("create_lobby", _params, %{assigns: %{}} = socket) do
    # I feel like I should do something with this return...
    GC.create_lobby()
    # TODO: move into lobby
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_lobby", %{"id" => id}, socket) do
    GC.delete_lobby(id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_all", _params, socket) do
    GC.get_lobbies() |> Enum.map(&GC.delete_lobby(&1.id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", %{"id" => id}, socket) do
    socket =
      case GC.start_game(id) do
        {:ok, _} ->
          socket |> assign(:game_id, id) |> redirect(to: "/#{id}")

        {:error, {:already_started, _pid}} ->
          socket |> assign(:game_id, id) |> redirect(to: "/#{id}")

        {:error, reason} ->
          socket
          |> put_flash(:error, "Error starting game #{id}, #{inspect(reason)}.")
          |> push_redirect(to: "/")
      end

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
