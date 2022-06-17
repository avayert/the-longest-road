defmodule Catan.Lobby do
  use GenServer, restart: :transient

  alias Catan.Utils
  alias Catan.Lobby.LobbySettings

  @type via_tuple :: {:via, module(), {module(), String.t()}}

  defmodule State do
    use TypedStruct

    @type lobby_settings :: LobbySettings.t()

    typedstruct enforce: false do
      field :id, String.t()
      field :players, [any()], default: []
      field :lobby_settings, lobby_settings
    end
  end


  @spec via(String.t()) :: via_tuple()
  def via(id) do
    {:via, Registry, {LobbyManager, id}}
  end

  def start_link(options) do
    lobby_settings = Keyword.get(options, :lobby_settings, [])

    state = %State{
      id: Keyword.fetch!(options, :id),
      lobby_settings: LobbySettings.new(lobby_settings)
    }

    GenServer.start_link(__MODULE__, state, options)
  end

  ## genserver callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:set_options, options}, _from, state) do
    state = Utils.update_map(state, options)
    {:reply, {:ok}, state}
  end

  ## public api

  def set_options(id, opts) do
    GenServer.call(via(id), {:set_options, opts})
  end
end

defmodule Catan.Lobby.LobbySettings do
  use TypedStruct

  @type game_speed :: :no_timer | :slow | :normal | :fast | :turbo

  typedstruct enforce: true do
    field :lobby_name, String.t(), default: "New Lobby"
    field :private, boolean(), default: true
    field :game_speed, game_speed, default: :normal
    field :max_players, pos_integer(), default: 4
    field :hand_limit, pos_integer(), default: 7
    field :win_vp, pos_integer(), default: 10
    field :game_mode, any(), default: nil, enforce: false
    field :map, any(), default: nil, enforce: false
  end

  def new(_opts \\ []) do
    %__MODULE__{}
  end
end
