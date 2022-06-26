defmodule Catan.Engine.GameMode.Standard do
  use Catan.Engine.GameMode
  require Logger

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

  # Maybe i shouldnt do this options thing and instead:
  # handle_phase(...) does some sort of choice mechanism
  # where it sends data back indicating a choice needs to be made
  # from the provided options like my current function does

  @impl true
  def init(state) do
    modestate = ModeState.new(state)
    {:ok, [action: :generate_board], modestate}
  end

  @impl true
  def handle_action([{:action, :generate_board}], state) do
    Logger.info("Pretending to generate map")
    {:ok, [action: :setup_board_state], state}
  end

  @impl true
  def handle_action([{:action, :setup_board_state}], state) do
    Logger.info("Pretending to setup the board state")
    {:ok, [phase: :choose_turn_order], state}
  end

  @impl true
  def phase_options([phase: :choose_turn_order], _state) do
    %{options: [action(:randomize), phase(:roll)]}
  end
end
