defmodule CatanWeb.MainLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.PubSub.Topics
  alias Catan.GameCoordinator, as: GC
  alias Catan.LobbyInfo

  import Catan.Utils, only: [unwrap: 1]

  @param_lobby_load_style "lobby_loading"
  @lobby_load_style_default :eager

  defp get_lobby_info(of) do
    GC.get_lobby_info(of) |> Catan.Utils.unwrap()
  end

  defp populate_lobbies(socket, :eager) do
    assign_new(socket, :lobbies, fn -> get_lobby_info(:all) end)
  end

  defp populate_lobbies(socket, :lazy) do
    assign(socket, :lobbies, [])
    # TODO
  end

  defp edit_lobbies(socket, id, :remove) when is_binary(id) do
    update(socket, :lobbies, &Enum.reject(&1, fn lobbyinfo -> lobbyinfo.id == id end))
  end

  # defp edit_lobbies(socket, id, op) when is_binary(id) do
  #   edit_lobbies(socket, get_lobby_info(id), op)
  # end

  defp edit_lobbies(socket, id, :add) when is_binary(id) do
    newlobby =
      with {:ok, result} when not is_list(result) <- GC.get_lobby_info(id) do
        [result]
      end

    update(socket, :lobbies, fn lobbies -> newlobby ++ lobbies end)
  end

  # defp edit_lobbies(socket, id, :update) when is_binary(id) do
  # end

  defp edit_lobbies(socket, id, :update) when is_binary(id) do
    update(
      socket,
      :lobbies,
      &Enum.map(&1, fn curlobbyinfo ->
        if curlobbyinfo.id == id do
          GC.get_lobby_info(id) |> unwrap()
        else
          curlobbyinfo
        end
      end)
    )
  end

  @impl true
  def mount(params, session, socket) do
    loading_method =
      case Map.get(params, @param_lobby_load_style) do
        "eager" -> :eager
        "lazy" -> :lazy
        _ -> @lobby_load_style_default
      end

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Catan.PubSub, Topics.lobbies())
        socket
      else
        socket
        # initial connect, pre ws connection
      end
      |> assign_new(:player_profile, fn -> session["player_profile"] end)
      |> populate_lobbies(loading_method)

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
    result = GC.delete_lobby(id)
    Logger.info("Deleted lobby #{id}, got #{inspect(result)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_all", _params, socket) do
    get_lobby_info(:all) |> Enum.map(&GC.delete_lobby(&1.id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", %{"id" => id}, socket) do
    Logger.alert("Handling start_game: #{inspect(id)}")

    socket =
      case GC.start_game(id) do
        {:ok, _} ->
          socket |> assign(:game_id, id) |> push_redirect(to: "/#{id}")

        {:error, {:already_started, _pid}} ->
          socket |> assign(:game_id, id) |> push_redirect(to: "/#{id}")

        {:error, reason} ->
          socket
          |> put_flash(:error, "Error starting game #{id}, #{inspect(reason)}.")
          |> push_redirect(to: "/")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_lobby, id}, socket) do
    {:noreply, socket |> edit_lobbies(id, :add)}
  end

  @impl true
  def handle_info({:delete_lobby, id}, socket) do
    {:noreply, socket |> edit_lobbies(id, :remove)}
  end

  @impl true
  def handle_info({:lobby_update, id}, socket) do
    {:noreply, socket |> edit_lobbies(id, :update)}
  end

  @impl true
  def handle_info({:start_game, id}, socket) do
    {:noreply, socket |> edit_lobbies(id, :remove)}
  end

  @impl true
  def handle_info(payload, socket) do
    Logger.info("#{__MODULE__} got unhandled payload: #{inspect(payload, pretty: true)}")
    {:noreply, socket}
  end
end
