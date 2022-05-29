defmodule Catan.Engine.Game do
  use GenServer

  defmodule State do
    use TypedStruct

    typedstruct do
      field :players, [%Catan.Engine.Player{}], default: []
      
    end
  end

  @doc """
  Start our queue and link it.
  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end

defmodule Catan.Engine.GameMode do
  use Behaviour

  @doc """
  Testing function
  """
  @callback testing(atom()) :: atom()
end

defmodule Catan.Engine.CatanStandard do
  @behaviour Catan.Engine.GameMode

  defmodule State do
    use TypedStruct

    alias Catan.Engine.{Player, GameSettings, GameMap}

    typedstruct do
      field :id, integer(), enforce: true

      field :players, [%Player{}], default: []
      field :game_settings, %GameSettings{}
      field :map, %GameMap{}

      field :winner, integer() | none(), default: nil
      # TODO new_deck()
      field :deck, list(), default: []
      # TODO
      field :bank, map(), default: %{}
      field :trades, list(), default: []
      field :building_supply, map()
    end

    def apparent_score(state, %Player{} = player) do
      0
    end

    def true_score(state, %Player{} = player) do
      1
    end
  end

  def new(id) do
  end
end
