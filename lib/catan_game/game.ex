defmodule Catan.Game do
  @moduledoc """
  TODO
  """

  use GenServer, restart: :transient

  defmodule State do
    use TypedStruct

    typedstruct do
      field :players, [Catan.Engine.Player.t()], default: []
      # global lobby settings
      # selected game
      # game specific lobby settings
    end
  end

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state), do: {:ok, state}
end

# TODO: reorganize engine folder to be catan_game/engine
