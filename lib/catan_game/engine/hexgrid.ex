defmodule Catan.Engine.Hexes.HexGrid do
  use Bitwise
  use TypedStruct

  alias Catan.Engine.Hexes
  alias Hexes.{HexTile, HexGrid}

  typedstruct do
    field :tiles, %{{integer(), integer()} => HexTile.t()}, default: %{}
  end

  @type tile :: HexTile.t()
  @type grid :: t()
  @type coords :: {integer(), integer()}
  @type coordlike :: tile | coords

  @type realtile :: {:real, tile}
  @type faketile :: {:fake, tile}
  @type maybetile :: realtile | faketile

  @type axial_offset :: {-1..1, -1..1}
  @type diag_offset :: {1, -2} | {2, -1} | {1, 1} | {-1, 2} | {-2, 1} | {-1, -1}

  @doc "TODO"
  defguard is_tile(item) when is_struct(item, HexTile)
  @doc "TODO"
  defguard is_coords(item) when is_tuple(item) and tuple_size(item) == 2
  @doc "TODO"
  defguard is_coordlike(item) when is_tile(item) or is_coords(item)

  @spec coords_from(coordlike) :: coords
  @doc "TODO"
  def coords_from(%HexTile{q: q, r: r}), do: {q, r}
  def coords_from({q, r} = item) when is_coords(item), do: item

  @spec new() :: t()
  @doc "TODO"
  def new() do
    %__MODULE__{}
  end

  @spec new_hexagon(integer()) :: grid
  @doc "TODO"
  def new_hexagon(radius) do
    # TODO
    new()
  end

  @spec s(tile) :: integer()
  @doc "TODO"
  def s(%HexTile{q: q, r: r}), do: -q - r

  @spec s(coords) :: integer()
  def s({q, r} = item) when is_coords(item), do: -q - r

  @spec add(coordlike, coordlike) :: {:fake, tile}
  @doc "TODO"
  def add(a, b) when is_coordlike(a) and is_coordlike(b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)

    {:fake, HexTile.new({q1 + q2, r1 + r2})}
  end

  @spec add(coordlike, coordlike, grid) :: maybetile
  def add(a, b, grid) when is_coordlike(a) and is_coordlike(b) do
    {_, tile} = add(a, b)
    get_tile(tile, grid)
    # case get_tile(tile, grid) do
    #   {:real, realtile} -> {:real, realtile}
    #   {:fake, faketile} -> {:fake, tile}
    # end
  end

  @spec get_tile(coordlike, grid) :: maybetile
  @doc "TODO"
  def get_tile(tile, %HexGrid{} = grid) when is_coordlike(tile) do
    coords = coords_from(tile)
    case Map.get(grid.tiles, coords, nil) do
      tile when is_tile(tile) -> {:real, tile}
      nil -> {:fake, HexTile.new(coords)}
    end
  end

  # Starts at upper left tile and goes clockwise
  @grid_vectors {{0, -1}, {1, -1}, {1, 0}, {0, 1}, {-1, 1}, {-1, 0}}

  # Starts at rightmost tile and goes counterclockwise
  @grid_vectors_alt {{1, 0}, {1, -1}, {0, -1}, {-1, 0}, {-1, 1}, {0, 1}}

  @spec get_neighbor(coordlike, axial_offset, grid) :: maybetile
  @doc "TODO"
  def get_neighbor(tile, offset, %HexGrid{} = grid) when is_coordlike(tile) do
    {_, tile} = get_tile(tile, grid)
    add(tile, offset, grid)
  end

  @spec get_neighbors(coordlike, grid) :: [maybetile]
  @doc "TODO"
  def get_neighbors(tile, grid = %HexGrid{}) when is_coordlike(tile) do
    for direction <- @grid_vectors, into: [] do
      get_neighbor(tile, grid, direction)
    end
  end

  @grid_diagonal_vectors {{1, -2}, {2, -1}, {1, 1}, {-1, 2}, {-2, 1}, {-1, -1}}

  @spec get_diagonal_neighbor(tile, grid, diag_offset) :: tile
  @doc "TODO"
  def get_diagonal_neighbor(tile = %HexTile{}, grid = %HexGrid{}, offset) do
    :todo
  end

  # TODO: rotation?
  # TODO: distances
  # TODO: pathfinding
  # (eastar, https://github.com/wkhere/eastar/blob/master/lib/examples/geo.ex)

  # put_tile(grid, {q, r})
  # put_tile(grid, tile)
  # get_tile(grid, {q, r})
end
