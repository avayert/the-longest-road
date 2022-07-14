defmodule Catan.Engine.GameMode.Standard do
  use Catan.Engine.GameMode
  require Logger

  import GameMode.Helpers

  alias Catan.LobbyOption
  alias Catan.Engine.Directive
  require Directive

  defmodule ModeState do
    use TypedStruct

    @default_deck [
      knight: 14,
      vp: 5,
      free_roads: 2,
      year_of_plenty: 2,
      monopoly: 2
    ]
    @default_bank [
      lumber: 19,
      grain: 19,
      wool: 19,
      ore: 19,
      brick: 19
    ]
    def default_supply,
      do: [
        settlement: 5,
        city: 4,
        road: 15
      ]

    @typep decktype :: keyword(non_neg_integer())
    @typep player_tmp :: struct()

    typedstruct do
      field :mode, module(), default: Catan.Engine.GameMode.Standard

      field :development_deck, decktype(), default: @default_deck
      field :bank, decktype(), default: @default_bank
      field :building_supply, %{player_tmp() => decktype()}, default: %{}

      field :longest_road, player_tmp() | nil, default: nil
      field :largest_army, player_tmp() | nil, default: nil

      field :trades, list(), default: []
      field :winner, player_tmp() | nil, default: nil
    end

    use Accessible

    def new(), do: %__MODULE__{}

    def new(game_state) do
      supply =
        for player <- game_state.lobby.players, reduce: %{} do
          acc -> Map.put_new(acc, player, ModeState.default_supply())
        end

      %__MODULE__{building_supply: supply}
    end
  end

  @impl true
  def lobby_options() do
    [
      LobbyOption.new(
        name: :win_vp,
        display_name: "VP to Win",
        type: :range,
        values: 3..20,
        default: 10
      ),
      LobbyOption.new(
        name: :max_players,
        display_name: "Max Players",
        type: :range,
        values: 1..4,
        default: 4
      ),
      LobbyOption.new(
        name: :hand_limit,
        display_name: "Card Discard Limit",
        type: :range,
        values: 2..99,
        default: 7
      ),
      LobbyOption.new(
        name: :starting_layout,
        display_name: "Starting Layout",
        type: :select,
        values: [:default, :crazy, :america, :canada, :europe],
        default: :default
      ),
      LobbyOption.new(
        name: :funky_mode,
        display_name: "New Funky Mode",
        type: :toggle,
        default: true
      ),
      LobbyOption.new(
        name: :name,
        display_name: "Lobby Name",
        type: :text,
        default: "New Lobby"
      ),
    ]
  end

  @impl true
  def init(state) do
    modestate = ModeState.new(state)
    {:ok, Directive.new(action: :generate_board), modestate}

    # Uncomment this when we actually have a lobby to test stuff with
    # {:ok, Directive.new(phase: :pregame_lobby), modestate}
  end

  @impl true
  def handle_step(
        [%Directive{op: {:phase, :pregame_lobby}}],
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Waiting for lobby")
    {:ok, Directive.new(action: :generate_board), state}
  end

  @impl true
  def handle_step(
        [%Directive{op: {:action, :generate_board}}],
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Pretending to generate map")

    state = struct!(state, map: :lol)

    {:ok, Directive.new(action: :setup_board_state), state}
  end

  @impl true
  def handle_step(
        [%Directive{op: {:action, :setup_board_state}}],
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Pretending to setup the board state")

    {:ok,
     Directive.new(
       phase: :choose_turn_order,
       choices:
         choices([
           action(:randomize),
           phase(:roll)
         ])
     ), state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:action, :randomize}},
          %Directive{op: {:phase, :choose_turn_order}}
        ],
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Randomizing turn order")
    {:ok, Directive.new(phase: :initial_placements), state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:phase, :roll}},
          %Directive{op: {:phase, :choose_turn_order}}
        ],
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Rolling for initiative")
    {:ok, Directive.new(phase: :initial_placements), state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:phase, :initial_placements}}
        ] = stack,
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Starting setup phase")
    {:ok, [Directive.new(phase: :round_1) | stack], state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:phase, :round_1}},
          %Directive{op: {:phase, :initial_placements}}
        ] = stack,
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Round 1 of placements")
    {:ok, [Directive.new(phase: :place_settlement) | stack], state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:phase, :place_settlement}},
          %Directive{op: {:phase, :round_1}},
          %Directive{op: {:phase, :initial_placements}}
        ] = stack,
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Awaiting settlement placement")
    {:ok, [Directive.new(phase: :place_road) | tl(stack)], state}
  end

  @impl true
  def handle_step(
        [
          %Directive{op: {:phase, :place_road}},
          %Directive{op: {:phase, :round_1}},
          %Directive{op: {:phase, :initial_placements}}
        ] = stack,
        state
      ) do
    Logger.info("[#{l_mod(2)}.#{l_fn()}:#{l_ln()}] Awaiting road placement")
    {:ok, [Directive.new(action: :next_player) | tl(stack)], state}
  end
end
