defmodule Catan.GameCoordinator do
  @moduledoc """
  Behold the enslaved pencil pusher turned genserver that manages setting up games
  and starting them.  This process encapsulates creating a new lobby (Game), putting
  players in that lobby, and handling their completion.  It also does stuff like
  reconnecting users, blah blah i'll finish this spiel later.
  """

  use GenServer

  require Logger

  alias Catan.Lobby

  defmodule State do
    use TypedStruct

    typedstruct do
      field :lobbies, %{String.t() => Lobby.t()}, default: %{}
    end

    use Accessible
  end

  @type via_tuple() :: {:via, module(), {module(), String.t()}}

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  ## Private functions

  @typep via_registries :: :game | :map | :player

  @spec via(id :: String.t(), type :: via_registries) :: via_tuple
  defp via(id, type) do
    case type do
      :game -> {:via, Registry, {GameRegistry, id}}
      :map -> {:via, Registry, {MapRegistry, id}}
      :player -> {:via, Registry, {PlayerRegistry, id}}
    end
  end

  defp unique_id?(id, type) do
    {_, _, {where, _}} = via(id, type)

    Registry.lookup(where, id)
    |> Enum.empty?()
  end

  defp new_id(type) do
    id = Catan.Utils.random_id()

    if unique_id?(id, type) do
      id
    else
      new_id(type)
    end
  end

  ## Testing stuff

  ## PubSub callbacks

  ## GenServer callbacks
  # Lobbies

  @impl true
  def handle_call({:create_lobby}, _from, state) do
    id = new_id(:game)
    lobby = Lobby.new(id)

    lobby_list =
      state.lobbies
      |> Map.put(id, lobby)

    state = %State{state | lobbies: lobby_list}

    # TODO: move lobby state to an agent or something
    #       so it doesnt die if the gc does

    {:reply, {id, lobby}, state}
  end

  @impl true
  def handle_call({:delete_lobby, id}, _from, state) do
    {got, state} = pop_in(state, [:lobbies, id])

    case got do
      nil -> {:reply, :noop, state}
      _ -> {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:get_lobby, id}, _from, state) do
    {:reply, Map.get(state.lobbies, id), state}
  end

  @impl true
  def handle_call({:get_lobbies}, _from, state) do
    {:reply, Map.values(state.lobbies), state}
  end

  @impl true
  def handle_call({:does_lobby_exist, id}, _from, state) do
    Map.fetch(state.lobbies, id)
    |> case do
      {:ok, %{}} -> {:reply, true, state}
      :error -> {:reply, false, state}
    end
  end

  @impl true
  def handle_call({:start_game, id}, _from, state) do
    {result, state} =
      case Map.get(state.lobbies, id) do
        nil -> {{:error, :no_lobby}, state}
        _lobby -> start_game(id, state)
      end

    {:reply, result, state}
  end

  ## Impl functions

  defp start_game(id, state) do
    lobby = Map.get(state.lobbies, id)
    opts = [name: via(id, :game), lobby: lobby]

    result =
      DynamicSupervisor.start_child(
        GameManager,
        {Catan.Game, opts}
      )
      |> case do
        {:ok, _pid} ->
          Logger.info("Started game: #{id}")
          {:ok, id}

        {:error, :no_lobby} = result ->
          Logger.error("Lobby does not exist: #{id}")
          result

        {:error, {:already_started, _pid}} = result ->
          Logger.error("Game already started: #{id}")
          result

        {:error, {_, stack}} = result when is_list(stack) ->
          Logger.error("error\n#{Exception.format_stacktrace(stack)}")
          result

        {:error, err} = result ->
          Logger.error("error\n#{inspect(err)}")
          result
      end

    state = put_in(state, [:lobbies, id, :game_started], true)

    {result, state}
  end

  ## Public API
  # Lobbies

  @spec create_lobby() :: {String.t(), Lobby.t()}
  def create_lobby() do
    GenServer.call(__MODULE__, {:create_lobby})
  end

  @spec delete_lobby(id :: String.t()) :: :ok
  def delete_lobby(id) do
    GenServer.call(__MODULE__, {:delete_lobby, id})
  end

  @spec get_lobby(id :: String.t()) :: Lobby.t() | nil
  def get_lobby(id) do
    GenServer.call(__MODULE__, {:get_lobby, id})
  end

  @spec get_lobbies() :: [Catan.Lobby.t()]
  def get_lobbies() do
    GenServer.call(__MODULE__, {:get_lobbies})
  end

  @spec lobby_exists?(id :: String.t()) :: boolean()
  def lobby_exists?(id) do
    GenServer.call(__MODULE__, {:does_lobby_exist, id})
  end

  @spec started?(id :: String.t()) :: boolean()
  def started?(id) do
    GenServer.call(__MODULE__, {:is_started, id})
  end

  # Games

  @spec start_game(id :: String.t()) :: :ok | {:error, atom()}
  def start_game(id) do
    GenServer.call(__MODULE__, {:start_game, id})
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
# defp via_tuple(id) do
#   {:via, Registry, {GameRegistry, id}}
# end
#
#
# opts = [name: via(id, :lobby), id: id]
#
# result =
#   DynamicSupervisor.start_child(
#     LobbyManager,
#     {Catan.Lobby, opts}
#   )
#   |> case do
#     {:error, _} = result ->
#       result |> IO.inspect(label: "bad thing happened")
#
#     {:ok, _pid} ->
#       IO.inspect("created lobby: #{id}")
#       {:ok, id}
#   end
