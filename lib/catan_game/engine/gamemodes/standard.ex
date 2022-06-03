defmodule Catan.Engine.CatanStandard do
  @behaviour Catan.Engine.GameMode

  defmodule State do
    use TypedStruct

    alias Catan.Engine.{Player, GameSettings}

    typedstruct do
      field :id, integer(), enforce: true

      field :players, [%Player{}], default: []
      field :game_settings, %GameSettings{}
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

    def apparent_score(_state, %Player{} = _player) do
      0
    end

    def true_score(_state, %Player{} = _player) do
      1
    end
  end

  def generate_board() do
    {:ok, nil}
  end
end
