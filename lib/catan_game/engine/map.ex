defmodule Catan.Engine.GameMap do
  @moduledoc """
  TODO
  """

  use GenServer

  alias Catan.Engine.{HexGrid, HexTile}

  import HexTile,
    only: [
      is_coordlike: 1,
      # is_coords: 1,
      is_tile: 1,
      coords_from: 1
    ]

  @type tile :: HexTile.t()
  @type grid :: HexGrid.t()
  @type coords :: HexTile.axial_coords()
  @type coordlike :: HexTile.coordlike()
  @type vector :: HexTile.axial_offset()

  defmodule State do
    use TypedStruct

    typedstruct do
      field :tilemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :edgemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :cornermap, HexGrid.grid(), default: HexGrid.new(:flat)
    end
  end

  @impl true
  def init(arg) do
    {:ok, {arg, %State{}}}
  end
end
