defmodule Catan.Engine.GameMode do
  @doc """
  Testing function
  """
  @callback generate_board() :: {:ok, any()}
end
