defmodule Catan.Engine.GameMode do
  @moduledoc false

  alias Catan.Engine.Directive

  @type stack :: Directive.stack()
  @type game_state :: Catan.Game.GameState.t()
  @type mode_state :: struct()
  @type dispatch_result ::
          {:ok, stack(), game_state()}
          | {:error, term()}
          | {:game_complete, game_state()}
          | :not_implemented

  @callback init(game_state :: game_state()) ::
              {:ok, Directive.t() | nil, mode_state()}

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

  @optional_callbacks [
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
      @type game_state :: GameMode.game_state()
      @type return_t :: GameMode.dispatch_result()

      @impl true
      @spec dispatch(
              stack :: stack(),
              state :: game_state()
            ) :: return_t()
      def dispatch([directive | _] = stack, state) do
        case directive.op do
          {:action, _} -> handle_step(stack, state)
          {:phase, _} -> handle_step(stack, state)
          {other, _} -> {:error, :unknown_op}
        end
      end

      @impl true
      def dispatch([], state) do
        {:error, :no_directives}
      end

      @impl true
      @spec handle_step(
              stack :: stack(),
              state :: game_state()
            ) :: return_t()
      def handle_step(stack, state) do
        :not_implemented
      end

      defoverridable dispatch: 2,
                     handle_step: 2
    end
  end
end
