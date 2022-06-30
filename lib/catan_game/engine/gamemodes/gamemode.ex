defmodule Catan.Engine.GameMode do
  @moduledoc false

  alias Catan.Engine.Directive

  @type stack :: Directive.stack()
  @type game_state :: Catan.Game.GameState.t()
  @type dispatch_result ::
          {:ok, stack(), struct()}
          | {:error, term()}
          | {:game_complete, struct()}
          | :not_implemented

  @callback init(game_state :: game_state()) ::
              {:ok, Directive.t() | nil, struct()}

  @callback dispatch(
              stack :: stack(),
              game_state :: game_state()
            ) :: dispatch_result()

  @callback handle_step(
              stack :: stack(),
              state :: game_state()
            ) :: dispatch_result()

  @callback handle_step(
              stack :: stack(),
              player :: any(),
              input :: any(),
              state :: game_state()
            ) :: dispatch_result()

  @callback handle_action(
              action :: stack(),
              state :: game_state()
            ) :: dispatch_result()

  @callback handle_action(
              action :: stack(),
              player :: any(),
              input :: any(),
              state :: game_state()
            ) :: dispatch_result()

  @callback handle_phase(
              phase :: stack(),
              state :: game_state()
            ) :: dispatch_result()

  # @callback handle_phase(
  #             phase :: Helpers.directives(),
  #             player :: any(),
  #             input :: any(),
  #             state :: game_state()
  #   ) :: dispatch_result()

  # @callback phase_options_wip(
  #             phase :: stack(),
  #             state :: game_state()
  #           ) :: %{required(:options) => [Directive.t(), ...]}

  @optional_callbacks [
    # phase_options_wip: 2,
    handle_step: 2,
    handle_step: 4
  ]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias Catan.Engine.GameMode
      @behaviour GameMode

      import GameMode.Helpers
      alias Catan.Engine.Directive

      @type stack :: GameMode.stack()
      @type game_state :: Catan.Game.GameState.t()
      @type return_t :: GameMode.dispatch_result()

      @impl true
      @spec dispatch(
              stack :: stack(),
              state :: game_state()
            ) :: return_t()
      def dispatch([directive | _] = stack, state) do
        case directive.op do
          {:action, _} -> handle_action(stack, state)
          {:phase, _} -> handle_phase(stack, state)
          {other, _} -> {:error, :unknown_op}
        end
      end

      def dispatch([], state) do
        {:error, :no_directives}
      end

      @impl true
      @spec handle_action(
              action :: {:action, atom()},
              player :: any(),
              input :: any(),
              state :: game_state()
            ) :: return_t()
      def handle_action(action, player, input, state) do
        :not_implemented
      end

      @impl true
      @spec handle_action(
              action :: {:action, atom()},
              state :: game_state()
            ) :: return_t()
      def handle_action(action, state) do
        :not_implemented
      end

      @impl true
      @spec handle_phase(
              phase :: {:phase, atom()},
              state :: game_state()
            ) :: return_t()
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
