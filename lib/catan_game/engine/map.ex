defmodule Catan.Engine.GameMap do
  alias Catan.Engine.Hexes
  use TypedStruct

  typedstruct do
    field :edgemap, %Hexes.HexGrid{}
    field :cornermap, %Hexes.HexGrid{}
  end
end
