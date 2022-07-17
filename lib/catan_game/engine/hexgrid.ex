defmodule Catan.Engine.HexGrid do
  @moduledoc """
  TODO
  """
  use Bitwise
  use TypedStruct

  alias Catan.Engine.{HexTile, HexGrid}

  import HexTile,
    only: [
      # is_coords: 1,
      is_coordlike: 1,
      # is_coordlike: 2,
      coords_from: 1
    ]

  @type tile :: HexTile.tile()
  @type grid :: t()
  @type coords :: HexTile.axial_coords()
  @type coordlike :: HexTile.coordlike()

  @type grid_orientation :: :pointy | :flat

  typedstruct do
    field :tiles, %{coords() => map()}, default: %{}
    field :orientation, grid_orientation(), default: :pointy
  end

  use Accessible

  defguard is_grid(item) when is_struct(item, HexGrid)

  ## Initializers

  @spec new() :: t()
  @doc "Create a new (pointy top) HexGrid"
  def new(), do: %__MODULE__{}

  @spec new(:pointy | :flat) :: t()
  @doc "Creates a new HexGrid of specified orientation"
  def new(:pointy), do: %__MODULE__{orientation: :pointy}
  def new(:flat), do: %__MODULE__{orientation: :flat}

  ## Data functions

  @spec get_data(grid, coordlike) :: map
  @doc "Get data on a tile from a grid"
  def get_data(grid, coords) when is_grid(grid) and is_coordlike(coords) do
    coords = coords_from(coords)
    Map.get(grid.tiles, coords, %{})
  end

  @spec put_data(grid, coordlike, map()) :: grid
  @doc "Insert (merge) data into the tilestate in a grid, overwriting if already present"
  def put_data(grid, tile, state)
      when is_grid(grid) and is_coordlike(tile) and is_map(state) do
    #
    coords = coords_from(tile)

    {_, new_tiles} =
      Map.get_and_update(grid.tiles, coords, fn cur ->
        {cur, Map.merge(cur || %{}, state)}
      end)

    %HexGrid{grid | tiles: new_tiles}
  end

  # @spec update_data(grid, coordlike, map()) :: grid
  # @doc "TODO"
  # def update_data(grid, tile, state)
  #     when is_grid(grid) and is_coordlike(tile) and is_map(state) do
  #   #
  #   :todo
  #   grid
  # end

  @spec clear_data(grid, coordlike) :: grid
  @doc "Clear tilestate data for a tile, resetting it to an empty map"
  def clear_data(grid, tile) when is_grid(grid) and is_coordlike(tile) do
    coords = coords_from(tile)
    new_tiles = Map.replace(grid.tiles, coords, %{})

    %HexGrid{grid | tiles: new_tiles}
  end
end
