defmodule CatanWeb.LobbyLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.PubSub.{Pubsub, Topics, Payloads}
  require Catan.PubSub.Pubsub

  import CatanWeb.Components.LobbyOption

  alias Catan.GameCoordinator, as: GC
  alias Catan.Lobby

  @impl true
  def mount(%{"id" => id} = params, session, socket) do
    socket =
      if GC.lobby_exists?(id) do
        setup_(params, session, socket)
      else
        fail(socket, "No lobby with ID #{id} found.")
      end

    if connected?(socket) do
      Pubsub.subscribe(Topics.lobby(id))

      Pubsub.broadcast(
        Topics.lobby(id),
        Payloads.lobby(:player_join, {id, session["player_profile"]})
      )
    end

    {:ok, socket}
  end

  defp setup_(%{"id" => id} = _params, session, socket) do
    with player = session["player_profile"],
         :ok <- Lobby.add_player(id, player) do
      socket
      |> assign(:game_id, id)
      |> assign(:player_profile, player)
      |> assign_new(:players, fn -> Lobby.get_players(id) end)
      |> assign_new(:lobby_options, fn -> Lobby.get_options(id) end)
      |> assign_new(:lobby_settings, fn -> Lobby.get_settings(id) end)
    else
      {:error, :lobby_full} ->
        fail(socket, "Lobby is full")
    end
  end

  defp fail(socket, message) do
    socket
    |> put_flash(:error, message)
    |> push_redirect(to: Routes.main_path(socket, :index))
  end

  # Liveview events

  @impl true
  def handle_event(
        "validate",
        %{"lobby_options" => changes} = _params,
        %{assigns: %{game_id: id} = _assigns} = socket
      ) do
    #
    Logger.info("Changes: #{inspect(changes)}")
    send_lobby_setting_update(id, changes)
    send_lobbyinfo_update(id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    {:noreply, socket |> put_flash(:error, "Not implemented yet")}
  end

  @impl true
  def handle_event("option_" <> option, _params, socket) do
    Logger.debug("not handling option event: #{option}")
    {:noreply, socket}
  end

  # Pubsub events

  @impl true
  def handle_info(
        {:delete_lobby, id},
        %{assigns: %{game_id: id}} = socket
      ) do
    #
    {:noreply, fail(socket, "Lobby #{id} destroyed")}
  end

  @impl true
  def handle_info(
        {:lobby_option_update, {_id, _}},
        socket
        # %{assigns: %{game_id: id}} = socket
      ) do
    # ignore updates from ourselves and update for others

    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_join, {id, _player}}, socket) do
    socket = socket |> assign(:players, Lobby.get_players(id))
    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    Logger.debug("#{__MODULE__} not handling #{inspect(event)}")
    {:noreply, socket}
  end

  # Helper functions

  defp send_lobby_setting_update(id, changes) do
    Pubsub.broadcast(
      Topics.lobby(id),
      Payloads.lobby(:lobby_option_update, {id, changes})
    )
  end

  defp send_lobbyinfo_update(id) do
    Pubsub.broadcast(
      Topics.lobbies(),
      Payloads.lobbies(:lobbyinfo_update, Lobby.get_lobby_info(id))
    )
  end
end
