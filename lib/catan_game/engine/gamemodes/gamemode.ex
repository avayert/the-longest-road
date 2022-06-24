defmodule Catan.Engine.GameMode do
  @moduledoc false

  alias Catan.Engine.GameMode.Helpers

  @callback init(initial_state :: any, opts :: keyword) :: Helpers.directive()

  # @callback setup_game_state(state :: gamestate) :: gamestate

  # # ok this wont work i need a way to get a map beforehand and just alter it
  # @callback generate_board(state :: gamestate) :: Catan.Engine.HexGrid.t()

  # @callback setup_board_state(state :: gamestate) :: gamestate

  # @callback choose_turn_order() :: any

  @optional_callbacks [
    # init: 2
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias Catan.Engine.GameMode
      @behaviour GameMode

      import GameMode.Helpers

      @type directive :: GameMode.Helpers.directive()

      # def init(initial_state, opts) do
      #   initial_state
      # end
    end
  end
end
