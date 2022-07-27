defmodule Catan.Lobby do
  require Logger

  alias Catan.PubSub.{Pubsub, Topics, Payloads}
  require Catan.PubSub.Pubsub

  use GenServer, restart: :transient

  defmodule State do
    use TypedStruct

    @type game_speed :: :none | :slow | :normal | :fast | :turbo
    # TODO: figure out a system to get times for different state directives

    typedstruct do
      field :id, String.t(), enforce: true

      field :name, String.t(), default: "New Lobby"
      field :players, [any()], default: []
      field :ready_states, %{struct() => boolean()}, default: %{}
      field :game_started, boolean(), default: false

      field :options, [Catan.LobbyOption.t()], default: []
      field :settings, %{atom() => any()}, default: %{}

      field :game_mode, module(), default: Catan.Engine.GameMode.Standard
      field :expansion, module(), default: nil
      field :scenarios, [module()], default: []

      # TODO: map stuff
      field :map_template, any(), default: nil
    end

    use Accessible

    def new(id, opts \\ []) do
      struct!(%__MODULE__{id: id}, opts)
      |> populate_settings()
    end

    defp populate_settings(state) do
      # TODO
      state
    end

    @spec ready?(state :: t()) :: boolean()
    def ready?(state) do
      Enum.all?(state.ready_states, fn {_, v} -> v end)
    end
  end

  @type t :: State.t()

  def set_setting(state, option, value) do
    result = State.set_setting(state, option, value)

    # TODO: this should probably be somewhere else
    # Pubsub.broadcast(
    #   Topics.lobby(state.id),
    #   Payloads.lobby(:lobby_update, state)
    # )

    result
  end

  def start_link(opts) do
    {name, state} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def broadcast_update(%State{id: id} = _state) do
    Pubsub.broadcast(Topics.lobbies(), Payloads.lobbies(:lobby_update, id))
  end

  def update_options(state) do
    options =
      (state.scenarios ++ [state.expansion, state.game_mode])
      |> Enum.reject(fn mode -> mode == nil end)
      |> Enum.map(fn mode -> mode.lobby_options() end)
      |> List.flatten()

    options = Catan.Lobby.BaseOptions.options() ++ options

    put_in(state, [:options], options)
  end

  defp via(id) do
    Catan.GameCoordinator.via(id, :lobby)
  end

  ## Impls

  @impl true
  def init(opts) do
    {id, opts} = Keyword.pop!(opts, :id)

    state =
      State.new(id, opts)
      |> update_options()

    Pubsub.subscribe(Topics.lobby(id))
    {:ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call({:get_lobby_info}, _from, state) do
    {:reply, Catan.LobbyInfo.from_state(state), state}
  end

  @impl true
  def handle_call({:starting}, _from, state) do
    state = %State{state | game_started: true}
    # do anything else needed before game start
    {:reply, state, state, :hibernate}
  end

  @impl true
  def handle_call({:add_player, player}, _from, state) do
    if length(state.players) < state.settings["max_players"] do
      state =
        update_in(state, [:players], fn players ->
          if player in players do
            players
          else
            [player | players]
          end
        end)

      {:reply, :ok, state}
    else
      {:reply, {:error, :lobby_full}, state}
    end
  end

  @impl true
  def handle_call({:remove_player, player_id}, _from, state) do
    state =
      update_in(state, [:players], fn players ->
        Enum.reject(players, &(&1.id == player_id))
      end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_players}, _from, state) do
    {:reply, state.players, state}
  end

  @impl true
  def handle_call(
        {:set_player_state, player_id, player_state},
        _from,
        state
      ) do
    #
    state =
      case player_state do
        %{ready: ready} ->
          update_in(state.ready_states, &Map.update!(&1, player_id, ready))

        # TODO: spectator, lobby leader

        thing ->
          Logger.info("Unhandled set_player_state #{inspect(thing)}")
          state
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_options}, _from, state) do
    {:reply, state.options, state}
  end

  @impl true
  def handle_call({:get_settings}, _from, state) do
    {:reply, Map.put(state.settings, "name", state.name), state}
  end

  # Public

  def get_options(id) do
    GenServer.call(via(id), {:get_options})
  end

  def get_settings(id) do
    GenServer.call(via(id), {:get_settings})
  end

  def get_lobby_info(id) do
    GenServer.call(via(id), {:get_lobby_info})
  end

  def add_player(id, player) do
    GenServer.call(via(id), {:add_player, player})
  end

  def remove_player(id, player) do
    GenServer.call(via(id), {:remove_player, player})
  end

  def get_players(id) do
    GenServer.call(via(id), {:get_players})
  end

  # Pubsub

  @impl true
  def handle_info({:lobby_option_update, {_id, changes, _}}, state) do
    # Logger.alert("lobby #{id} got changes #{inspect(changes)}\nHave state: #{inspect(state)}")

    {changes, state} =
      Map.pop(changes, "name")
      |> case do
        {nil, changes} -> {changes, state}
        {name, changes} -> {changes, put_in(state.name, name)}
      end

    state = update_in(state.settings, &Map.merge(&1, changes))
    {:noreply, state}
  end

  @impl true
  def handle_info(event, socket) do
    # Logger.debug("#{__MODULE__} not handling #{inspect(event)}")
    {:noreply, socket}
  end
end

defmodule Catan.Lobby.BaseOptions do
  alias Catan.LobbyOption

  @game_speeds [:none, :slow, :normal, :fast, :turbo]

  def options do
    [
      LobbyOption.new(
        name: :private_game,
        display_name: "Private game",
        type: :toggle,
        default: true
      ),
      LobbyOption.new(
        name: :game_speed,
        display_name: "Game speed",
        event: false,
        type: :select,
        values: @game_speeds,
        default: :normal
      )
    ]
  end
end
