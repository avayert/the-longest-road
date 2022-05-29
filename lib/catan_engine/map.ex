defmodule Catan.Engine.GameMap do
  use TypedStruct

  typedstruct do
    field :edgemap, %Catan.Engine.HexGrid{}
    field :cornermap, %Catan.Engine.HexGrid{}
  end
end
