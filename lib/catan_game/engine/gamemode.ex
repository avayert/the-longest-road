defmodule Catan.Engine.GameMode do
  @moduledoc false

  defmodule GameState do
    use TypedStruct

    typedstruct do
      field :opts, keyword()
    end
  end

  # @typep gamestate :: GameState.t()

  @callback init(opts :: keyword) :: :ok | {:error, any}

  # @callback setup_game_state(state :: gamestate) :: gamestate

  # # ok this wont work i need a way to get a map beforehand and just alter it
  # @callback generate_board(state :: gamestate) :: Catan.Engine.HexGrid.t()

  # @callback setup_board_state(state :: gamestate) :: gamestate

  # @callback choose_turn_order() :: any

  @optional_callbacks [
    init: 1
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Catan.Engine.GameMode

      import Catan.Engine.GameMode.Helpers

      def init(opts) do
        :ok
      end
    end
  end
end
