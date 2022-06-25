defmodule Catan.Engine.GameMode do
  @moduledoc false

  alias Catan.Engine.GameMode.Helpers

  @type gamestate :: Catan.Game.GameState.t()

  @callback init(game_state :: gamestate()) ::
              {:ok, struct(), Helpers.directive() | nil}

  # @optional_callbacks [
  #   # init: 1
  # ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias Catan.Engine.GameMode
      @behaviour GameMode

      alias GameMode.Helpers
      import GameMode.Helpers

      @type directive :: Helpers.directive()
      @type gamestate :: Catan.Game.GameState.t()
      @type directive_result :: Helpers.directive_result()

      @spec handle_action(
              action :: Helpers.game_action(),
              state :: gamestate
            ) :: directive_result()
      def handle_action(action, state) do
        {:not_implemented, state}
      end

      @spec handle_phase(
              phase :: Helpers.game_phase(),
              state :: gamestate
            ) :: directive_result()
      def handle_phase(phase, state) do
        {:not_implemented, state}
      end

      @spec handle_phase(
              directive :: Helpers.directive(),
              state :: gamestate
            ) :: directive_result()
      def handle_directive(directive, state) do
        :not_implemented
      end

      defoverridable handle_action: 2, handle_phase: 2, handle_directive: 2
    end
  end
end
