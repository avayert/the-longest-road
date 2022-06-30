defmodule Catan.Engine.GameMode.Helpers do
  @moduledoc """
  Contains the `action` and `phase` macros
  """

  @doc """
  Defines a catan game phase.

  Shorthand for `{:phase, name}`
  """
  defmacro phase(name) do
    quote bind_quoted: [name: name] do
      [{:phase, name}]
    end
  end

  @doc """
  Defines a catan game action.

  Shorthand for `{:action, name}`
  """
  defmacro action(name) do
    quote bind_quoted: [name: name] do
      [{:action, name}]
    end
  end
end
