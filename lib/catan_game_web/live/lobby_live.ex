defmodule CatanWeb.LobbyLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.PubSub.{Pubsub, Topics, Payloads}
  require Catan.PubSub.Pubsub

  import CatanWeb.Components.LobbyOption

  alias Catan.GameCoordinator, as: GC

  @impl true
  def mount(%{"id" => id} = _params, session, socket) do
    socket =
      if GC.lobby_exists?(id) do
        socket
        |> assign(:game_id, id)
        |> assign(:player_profile, session["player_profile"])
        |> assign_new(:lobby_options, fn -> Catan.Lobby.get_options(id) end)
        |> assign(:lobby_settings, %{})
      else
        socket
        |> put_flash(:error, "No lobby with ID #{id} found.")
        |> push_redirect(to: Routes.main_path(socket, :index))
      end

    if connected?(socket) do
      Pubsub.subscribe(Topics.lobby(id))
    end

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        _params,
        %{
          assigns: %{game_id: _id} = _assigns
        } = socket
      ) do
    #
    Logger.info("Validating")
    # put form state somewhere
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "lobby_name_changed",
        %{"lobby_options" => %{"lobby_name" => _name}} = _params,
        %{assigns: %{game_id: id}} = socket
      ) do
    #
    Phoenix.PubSub.broadcast!(
      Catan.PubSub,
      Topics.lobbies(),
      {:lobby_name_changed, {id, "new_name"}}
    )

    Logger.info("lobby name changed")

    {:noreply, socket}
  end

  @impl true
  def handle_event("option_" <> option, _params, %{assigns: %{}} = socket) do
    Logger.debug("not handling option event #{option}")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:delete_lobby, id}, socket) do
    socket =
      if socket.assigns.game_id == id do
        socket
        |> put_flash(:error, "Lobby #{id} destroyed")
        |> push_redirect(to: Routes.main_path(socket, :index))
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
