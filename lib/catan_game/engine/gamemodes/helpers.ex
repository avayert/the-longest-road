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
      # [{:phase, name}]
      {:phase, name}
    end
  end

  @doc """
  Defines a catan game action.

  Shorthand for `{:action, name}`
  """
  defmacro action(name) do
    quote bind_quoted: [name: name] do
      # [{:action, name}]
      {:action, name}
    end
  end

  @doc """
  Flattens a list of directive ops.

  Shorthand for `List.flatten(items)`
  """
  defmacro choices(items) do
    quote do
      List.flatten(unquote(items))
    end
  end

  defmacro l_mod(bases \\ 1) do
    __CALLER__.module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.take(-bases)
    |> Enum.join(".")
  end

  defmacro l_fn do
    __CALLER__.function
    |> then(&"#{elem(&1, 0)}")
  end

  defmacro l_fna do
    __CALLER__.function
    |> then(&"#{elem(&1, 0)}/#{elem(&1, 1)}")
  end

  defmacro l_ln do
    __CALLER__.line |> Integer.to_string()
  end
end
