defmodule Catan.Engine.GameModes.Standard do
  use Catan.Engine.GameMode

  defmodule State do
    use TypedStruct

    alias Catan.Engine.{Player, GameSettings}

    typedstruct do
      field :id, integer(), enforce: true

      field :players, [Player.t()], default: []
      field :game_settings, GameSettings.t()
      # oh no
      field :map, atom()

      field :winner, integer() | none(), default: nil
      # TODO new_deck()
      field :deck, list(), default: []
      # TODO
      field :bank, map(), default: %{}
      field :trades, list(), default: []
      field :building_supply, map()
    end
  end

  # how do i actually do states
  # states are like a stack so i cant just make a list
  # I think i actually need functions to trace the state path
  # i could have either a bunch of functions that return other functions or whatever
  # OR i can have one function with a big fucking case but that might have issues

  def generate_board() do
    {:ok, nil}
  end

  def handle_action({:action, opts}, state) do
    {:idk, :next_state, {:something?, opts}, state}
  end
end
