defmodule Catan.Lobby do
  use TypedStruct

  alias Catan.Utils

  @type game_speed :: :no_timer | :slow | :normal | :fast | :turbo

  typedstruct do
    field :id, String.t(), enforce: true
    field :game_started, boolean()
    field :players, [any()], default: []
    field :ready_states, %{struct() => boolean()}
    field :lobby_name, String.t(), default: "New Lobby"
    field :private_lobby, boolean(), default: true
    field :game_speed, game_speed, default: :normal
    field :max_players, pos_integer(), default: 4
    field :hand_limit, pos_integer(), default: 7
    field :win_vp, pos_integer(), default: 10
    field :game_mode, any(), default: nil
    field :map, any(), default: nil
  end

  def new(id, opts \\ []) do
    %__MODULE__{id: id} |> Utils.update_map(opts)
  end

  @spec set_settings(state :: t(), opts :: keyword()) :: t()
  def set_settings(state, opts) do
    Utils.update_map(state, opts)
  end

  @spec ready?(state :: t()) :: boolean()
  def ready?(state) do
    Enum.all?(state.ready_states, fn {_, v} -> v end)
  end
end

# defmodule Catan.LobbyBad do
#   use GenServer, restart: :transient

#   alias Catan.Utils
#   alias Catan.Lobby.LobbySettings

#   @type via_tuple :: {:via, module(), {module(), String.t()}}

#   defmodule State do
#     use TypedStruct

#     @type lobby_settings :: LobbySettings.t()

#     typedstruct enforce: false do
#       field :id, String.t()
#       field :ingame, boolean()
#       field :players, [any()], default: []
#       field :ready_states, %{struct() => boolean()}
#       field :lobby_settings, lobby_settings
#     end
#   end

#   @spec via(String.t()) :: via_tuple()
#   def via(id) do
#     {:via, Registry, {LobbyManager, id}}
#   end

#   def start_link(options) do
#     lobby_settings = Keyword.get(options, :lobby_settings, [])

#     state = %State{
#       id: Keyword.fetch!(options, :id),
#       lobby_settings: LobbySettings.new(lobby_settings)
#     }

#     GenServer.start_link(__MODULE__, state, options)
#   end

#   ## genserver callbacks

#   @impl true
#   def init(state) do
#     {:ok, state}
#   end

#   @impl true
#   def handle_call({:set_settings, options}, _from, state) do
#     state = Utils.update_map(state, options)
#     {:reply, :ok, state}
#   end

#   @impl true
#   def handle_call({:get_settings}, _from, state) do
#     {:reply, state.lobby_settings, state}
#   end

#   @impl true
#   def handle_call({:is_ready}, _from, state) do
#     ready = Enum.all?(state.ready_states, fn {_, v} -> v end)
#     {:reply, ready, state}
#   end

#   ## public api

#   @spec set_settings(id :: String.t(), opts :: keyword()) :: :ok
#   def set_settings(id, opts) do
#     GenServer.call(via(id), {:set_settings, opts})
#   end

#   @spec get_settings(id :: String.t()) :: Catan.Lobby.LobbySettings.t()
#   def get_settings(id) do
#     GenServer.call(via(id), {:get_settings})
#   end

#   @spec ready?(id :: String.t()) :: boolean()
#   def ready?(id) do
#     GenServer.call(via(id), {:is_ready})
#   end

#   @spec start(id :: String.t()) :: any()
#   def start(id) do
#     Catan.GameCoordinator.start_game(id)
#   end
# end
