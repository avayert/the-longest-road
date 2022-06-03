defmodule Catan.Engine.GameMap do
  alias Catan.Engine.Hexes
  use GenServer

  defmodule State do
    use TypedStruct

    typedstruct do
      field :edgemap, %Hexes.HexGrid{}
      field :cornermap, %Hexes.HexGrid{}
    end
  end

  @impl true
  def init(arg) do
    {:ok, {arg, %State{}}}
  end
end
