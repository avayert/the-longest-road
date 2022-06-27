defmodule Catan.Engine.GameMode do
  @moduledoc false

  alias Catan.Engine.GameMode.Helpers

  @type game_state :: Catan.Game.GameState.t()

  @callback init(game_state :: game_state()) ::
              {:ok, Helpers.directive() | nil, struct()}

  @callback dispatch(
              directives :: Helpers.directives(),
              game_state :: game_state()
            ) :: Helpers.directive_result()

  @callback handle_action(
              action :: Helpers.directives(),
              state :: game_state()
            ) :: Helpers.directive_result()

  @callback handle_action(
              action :: Helpers.directives(),
              player :: any(),
              input :: any(),
              state :: game_state()
            ) :: Helpers.directive_result()

  @callback handle_phase(
              phase :: Helpers.directives(),
              state :: game_state()
            ) :: Helpers.directive_result()

  # @callback handle_phase(
  #             phase :: Helpers.directives(),
  #             player :: any(),
  #             input :: any(),
  #             state :: game_state()
  #   ) :: Helpers.directive_result()

  @callback phase_options(
              phase :: Helpers.directives(),
              state :: game_state()
            ) :: %{required(:options) => [Helpers.directive(), ...]}

  @optional_callbacks [
    phase_options: 2
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias Catan.Engine.GameMode
      @behaviour GameMode

      alias GameMode.Helpers
      import GameMode.Helpers

      @type directive :: Helpers.directive()
      @type game_state :: Catan.Game.GameState.t()
      @type directive_result :: Helpers.directive_result()

      @impl true
      @spec dispatch(
              directives :: Helpers.directives(),
              state :: game_state()
            ) :: directive_result()
      def dispatch([directive | _] = directives, state) do
        case directive do
          {:action, _} -> handle_action(directives, state)
          {:phase, _} -> handle_phase(directives, state)
        end
      end

      @impl true
      @spec handle_action(
              action :: Helpers.game_action(),
              player :: any(),
              input :: any(),
              state :: game_state()
            ) :: directive_result()
      def handle_action(action, player, input, state) do
        :not_implemented
      end

      @impl true
      @spec handle_action(
              action :: Helpers.game_action(),
              state :: game_state()
            ) :: directive_result()
      def handle_action(action, state) do
        :not_implemented
      end

      @impl true
      @spec handle_phase(
              phase :: Helpers.game_phase(),
              state :: game_state()
            ) :: directive_result()
      def handle_phase(phase, state) do
        :not_implemented
      end

      defoverridable dispatch: 2,
                     handle_action: 2,
                     handle_action: 4,
                     handle_phase: 2
    end
  end
end
