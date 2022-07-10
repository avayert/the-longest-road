defmodule Catan.GameCoordinator do
  @moduledoc """
  Behold the enslaved pencil pusher turned genserver that manages setting up games
  and starting them.  This process encapsulates creating a new lobby (Game), putting
  players in that lobby, and handling their completion.  It also does stuff like
  reconnecting users, blah blah i'll finish this spiel later.
  """

  use GenServer

  require Logger

  alias Catan.PubSub.Topics
  alias Catan.Engine.Player, as: Player

  @type error_tuple :: {:error, atom()}
  @type via_tuple() :: {:via, module(), {module(), String.t()}}
  @typep via_registries :: :lobby | :game | :map | :player

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec via(id :: String.t(), type :: via_registries) :: via_tuple
  def via(id, type) do
    {:via, Registry, {get_registry(type), id}}
  end

  # Private functions

  defp get_registry(type) do
    case type do
      :lobby -> LobbyRegistry
      :game -> GameRegistry
      :map -> MapRegistry
      :player -> PlayerRegistry
    end
  end

  defp unique_id?(id, type) do
    get_registry(type)
    |> Registry.lookup(id)
    |> Enum.empty?()
  end

  defp exists?(id, type) do
    not unique_id?(id, type)
  end

  defp new_id(type) do
    new_id(type, nil, false)
  end

  defp new_id(type, _id, false) do
    id = Catan.Utils.random_id()
    new_id(type, id, unique_id?(id, type))
  end

  defp new_id(_type, id, true) do
    id
  end

  defp get_all_ids(type) do
    get_registry(type)
    |> Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  # Testing stuff

  # PubSub callbacks

  # GenServer callbacks
  ## Generic

  @impl true
  def handle_call({:exists, id, type}, _from, state) do
    {:reply, exists?(id, type), state}
  end

  ## Lobbies

  ### create_lobby(player \\ nil)

  @impl true
  def handle_call({:create_lobby, player}, _from, state)
      when is_struct(player, Player) or is_nil(player) do
    #
    id = new_id(:lobby)

    # TODO: deuglyfy
    opts =
      [name: via(id, :lobby), id: id] ++
        if player != nil, do: [players: [player]], else: []

    result =
      DynamicSupervisor.start_child(
        LobbyManager,
        {Catan.Lobby, opts}
      )
      |> case do
        {:ok, _pid} ->
          Logger.info("[GC] Started lobby: #{id}")
          {:ok, id}

        {:error, {err, stack}} = result when is_list(stack) ->
          Logger.error(
            "[GC] Error starting lobby, #{inspect(err)}:\n#{Exception.format_stacktrace(stack)}"
          )

          result

        {:error, err} = result ->
          Logger.error("[GC] Error starting lobby:\n#{inspect(err)}")
          result
      end

    Phoenix.PubSub.broadcast!(Catan.PubSub, Topics.lobbies(), {:new_lobby, id})

    {:reply, result, state}
  end

  ### delete_lobby(id)

  @impl true
  def handle_call({:delete_lobby, id}, _from, state) do
    result =
      if exists?(id, :lobby) do
        GenServer.call(via(id, :lobby), :stop)

        Phoenix.PubSub.broadcast!(
          Catan.PubSub,
          Topics.lobbies(),
          {:delete_lobby, id}
        )

        :ok
      else
        {:error, :no_lobby}
      end

    {:reply, result, state}
  end

  ### get_all_lobbies()

  @impl true
  def handle_call({:get_all_lobbies}, _from, state) do
    {:reply, get_all_ids(:lobby), state}
  end

  ### get_lobby_info(id)
  # TODO: maybe lobby info cache process

  @impl true
  def handle_call({:get_lobby_info, :all}, _from, state) do
    results =
      for id <- get_all_ids(:lobby) do
        Task.async(fn ->
          GenServer.call(via(id, :lobby), {:get_lobby_info})
        end)
      end
      |> Task.await_many()

    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call({:get_lobby_info, id}, _from, state) do
    info = GenServer.call(via(id, :lobby), {:get_lobby_info})
    # TODO: handle bad id
    {:reply, {:ok, info}, state}
  end

  # Games

  ### start_game(lobby_id)

  @impl true
  def handle_call({:start_game, id}, _from, state) do
    result =
      if exists?(id, :lobby) do
        start_game_(id, state)
      else
        {:error, :no_lobby}
      end

    {:reply, result, state}
  end

  ### delete_game(id)

  @impl true
  def handle_call({:delete_game, id}, _from, state) do
    result = GenServer.stop(via(id, :game), :normal)
    # TODO: remove lobby or reset lobby?
    {:reply, result, state}
  end

  ### get_all_games()

  @impl true
  def handle_call({:get_all_games}, _from, state) do
    ids = Registry.select(GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    # Registry.select(MyRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
    {:reply, {:ok, ids}, state}
  end

  ### unfinished player functions

  @impl true
  def handle_call({:register_player, _player}, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_player, _id}, _from, state) do
    {:reply, :ok, state}
  end

  ## Impl functions

  defp start_game_(id, _state) do
    lobby = GenServer.call(via(id, :lobby), {:starting})
    opts = [name: via(id, :game), lobby: lobby]

    result =
      DynamicSupervisor.start_child(
        GameManager,
        {Catan.Game, opts}
      )
      |> case do
        {:ok, _pid} ->
          Logger.info("[GC] Starting game: #{id}")

          Phoenix.PubSub.broadcast!(
            Catan.PubSub,
            Topics.lobbies(),
            {:start_game, id}
          )

          {:ok, id}

        {:error, {:already_started, _pid}} = result ->
          Logger.error("[GC] Game already started: #{id}")
          result

        {:error, {_, stack}} = result when is_list(stack) ->
          Logger.error("[GC] Error starting game:\n#{Exception.format_stacktrace(stack)}")
          result

        {:error, err} = result ->
          Logger.error("[GC] Error starting game:\n#{inspect(err)}")
          result
      end

    result
  end

  ## Public API
  # Lobbies

  @spec create_lobby(player :: Player.t()) ::
          {:ok, String.t()} | error_tuple()
  def create_lobby(player \\ nil) do
    GenServer.call(__MODULE__, {:create_lobby, player})
  end

  @spec delete_lobby(id :: String.t()) :: :ok | error_tuple()
  def delete_lobby(id) do
    GenServer.call(__MODULE__, {:delete_lobby, id})
  end

  @spec get_all_lobbies() :: {:ok, [Catan.Lobby.t()]} | error_tuple()
  def get_all_lobbies() do
    GenServer.call(__MODULE__, {:get_all_lobbies})
  end

  @spec get_lobby_info(id :: String.t() | :all) ::
          {:ok, Catan.LobbyInfo.t() | [Catan.LobbyInfo.t()]} | error_tuple()
  def get_lobby_info(id) do
    GenServer.call(__MODULE__, {:get_lobby_info, id})
  end

  @spec lobby_exists?(id :: String.t()) :: boolean()
  def lobby_exists?(id) do
    GenServer.call(__MODULE__, {:exists, id, :lobby})
  end

  # @spec started?(id :: String.t()) :: boolean()
  # def started?(id) do
  #   GenServer.call(__MODULE__, {:is_started, id})
  # end

  # Games

  @spec start_game(lobby_id :: String.t()) :: :ok | error_tuple()
  def start_game(lobby_id) do
    GenServer.call(__MODULE__, {:start_game, lobby_id})
  end

  @spec delete_game(id :: String.t()) :: :ok | error_tuple()
  def delete_game(id) do
    GenServer.call(__MODULE__, {:delete_game, id})
  end

  @spec get_all_games() :: {:ok, [String.t()]} | error_tuple()
  def get_all_games() do
    GenServer.call(__MODULE__, {:get_all_games})
  end

  @spec game_exists?(id :: String.t()) :: boolean()
  def game_exists?(id) do
    GenServer.call(__MODULE__, {:exists, id, :game})
  end

  # Players

  def register_player(_player) do
    :not_implemented
  end

  def get_player(_id) do
    :not_implemented
  end

  # testing functions
end

########################
# @impl true
# def handle_call({:join_game, id, player}, _from, state) do
#   try do
#     :ok = GenServer.call(via_tuple(id), {:add_player, player})
#   catch
#     :exit, e -> Logger.warning("Couldn't join_game: #{inspect(e)}")
#   end
#   {:reply, id, state, {:continue, :tick}}
# end
########################
