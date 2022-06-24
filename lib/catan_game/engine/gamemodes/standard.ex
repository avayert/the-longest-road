defmodule Catan.Engine.GameMode.Standard do
  use Catan.Engine.GameMode

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
    @default_supply [
      settlement: 5,
      city: 4,
      road: 15
    ]

    @typep decktype :: keyword(non_neg_integer())

    typedstruct do
      field :mode, module(), default: __MODULE__

      field :development_deck, decktype(), default: @default_deck
      field :bank, decktype(), default: @default_bank
      field :building_supply, %{any() => decktype()}, default: %{}

      field :trades, list(), default: []
      field :winner, term() | nil, default: nil
    end

    use Accessible

    def new(), do: %__MODULE__{}
  end

  # how do i actually do states
  # states are like a stack so i cant just make a list
  # I think i actually need functions to trace the state path
  # i could have either a bunch of functions that return other functions or whatever
  # OR i can have one function with a big fucking case but that might have issues

  def init(_state, _opts) do
    {:ok, action(:generate_board)}
  end

  def generate_board() do
    {:ok, nil}
  end

  def handle_action({:action, opts}, state) do
    {:idk, :next_state, {:something?, opts}, state}
  end
end
