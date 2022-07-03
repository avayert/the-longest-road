defmodule CatanWeb.GameLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.GameCoordinator, as: GC

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      if GC.lobby_exists?(id) do
        socket
        |> assign(:game_id, id)
      else
        socket
        |> put_flash(:error, "No lobby with ID #{id} found.")
        |> push_redirect(to: "/")
      end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Catan.PubSub, "gc:lobbies")
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("player_input", params, %{assigns: %{game_id: game_id}} = socket) do
    Phoenix.PubSub.broadcast!(Catan.PubSub, "game:#{game_id}", {:player_input, params})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:delete_lobby, id}, socket) do
    socket =
      if socket.assigns.game_id == id do
        socket
        |> put_flash(:error, "Lobby #{id} destroyed")
        |> push_redirect(to: "/")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(thing, socket) do
    Logger.debug("#{__MODULE__} not handling #{inspect(thing)}")
    {:noreply, socket}
  end
end