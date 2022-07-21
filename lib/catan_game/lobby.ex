defmodule Catan.Lobby do
  require Logger

  alias Catan.PubSub.Topics

  use GenServer, restart: :transient

  defmodule State do
    use TypedStruct

    @type game_speed :: :none | :slow | :normal | :fast | :turbo
    # TODO: figure out a system to get times for different state directives

    typedstruct do
      field :id, String.t(), enforce: true

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
    end

    @spec set_setting(state :: t(), option :: atom(), value :: any()) :: State.t()
    def set_setting(state, option, value) when is_atom(option) do
      update_in(state, [:settings, option], value)
    end

    @spec get_setting(state :: t(), setting :: atom()) :: {State.t(), any()}
    def get_setting(state, setting) do
      Enum.find(state.options, fn {opt, _val} -> opt.name == setting end)
    end

    @spec get_setting_value(state :: t(), setting :: atom()) :: any()
    def get_setting_value(state, setting) do
      Enum.find(state.options, fn {opt, val} when opt.name == setting -> val end)
    end

    @spec ready?(state :: t()) :: boolean()
    def ready?(state) do
      Enum.all?(state.ready_states, fn {_, v} -> v end)
    end
  end

  @type t :: State.t()

  defdelegate get_setting(state, option), to: State
  defdelegate get_setting_value(state, option), to: State

  def set_setting(state, option, value) do
    result = State.set_setting(state, option, value)

    Phoenix.PubSub.broadcast!(
      Catan.PubSub,
      Topics.lobby(state.id),
      {:lobby_update, state}
    )

    result
  end

  def start_link(opts) do
    {name, state} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def broadcast_update(%State{id: id} = _state) do
    Phoenix.PubSub.broadcast!(
      Catan.PubSub,
      Topics.lobbies(),
      {:lobby_update, id}
    )
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

  ## Impls

  @impl true
  def init(opts) do
    {id, opts} = Keyword.pop!(opts, :id)

    state =
      State.new(id, opts)
      |> update_options()

    Phoenix.PubSub.subscribe(Catan.PubSub, Topics.lobby(id))
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
    if length(state.players) < get_setting_value(state, :max_players) do
      state = update_in(state, [:players], &[player | &1])

      {:reply, :ok, state}
    else
      {:reply, :error, :lobby_full}
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
  def handle_call({:update_settings, _whatever}, _from, state) do
    {:reply, :nyi, state}
  end

  @impl true
  def handle_call(:get_options, _from, state) do
    {:reply, state.options, state}
  end

  def get_options(id) do
    GenServer.call(Catan.GameCoordinator.via(id, :lobby), :get_options)
  end
end

defmodule Catan.Lobby.BaseOptions do
  alias Catan.LobbyOption

  @game_speeds [:none, :slow, :normal, :fast, :turbo]

  def options do
    [
      LobbyOption.new(
        name: :lobby_name,
        display_name: "Lobby name",
        type: :text,
        default: "New Lobby"
      ),
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
