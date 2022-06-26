defmodule Catan.Engine.GameMode.Helpers do
  @moduledoc false

  @type game_action :: {:action, atom()}
  @type game_phase :: {:phase, atom()}
  @type directive :: game_action | game_phase

  @type directives :: [directive]

  @type directive_result ::
          {:ok, term(), struct()}
          | :not_implemented
          | :game_complete

  # I might need different ops than just :ok
  # like to explicitly skip/defer/update_and_continue

  @doc """
  Defines a catan game phase.

  Shorthand for `{:phase, name}`
  """
  defmacro phase(name) do
    quote bind_quoted: [name: name] do
      {:phase, name}
    end
  end

  @doc """
  Defines a catan game action.

  Shorthand for `{:action, name}`
  """
  defmacro action(name) do
    quote bind_quoted: [name: name] do
      {:action, name}
    end
  end
end
