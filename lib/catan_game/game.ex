defmodule Catan.Game do
  use GenServer

  defmodule State do
    use TypedStruct

    typedstruct do
      field :players, [%Catan.Engine.Player{}], default: []
      # global lobby settings
      # selected game
      # game specific lobby settings
    end
  end

  @doc """
  Start our queue and link it.
  This is a helper function
  """
  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end

# TODO: reorganize engine folder to be catan_game/engine
