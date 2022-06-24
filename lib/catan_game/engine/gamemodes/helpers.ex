defmodule Catan.Engine.GameMode.Helpers do
  @moduledoc false

  @type game_action :: {:action, atom(), keyword()}
  @type game_state :: {:state, atom(), keyword()}
  @type directive :: game_action | game_state

  @doc """
  Defines a catan game state.

  Shorthand for `{:state, name, opts || []}`
  """
  defmacro state(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      {:state, name, opts}
    end
  end

  @doc """
  Defines a catan game action.

  Shorthand for `{:action, name, opts || []}`
  """
  defmacro action(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      {:action, name, opts}
    end
  end
end
