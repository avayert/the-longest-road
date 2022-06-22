defmodule Catan.Engine.GameMode.Helpers do
  @moduledoc false

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
