defmodule Catan.Engine.Hexes.HexGrid do
  use Bitwise
  use TypedStruct

  alias Catan.Engine.Hexes
  alias Hexes.{HexTile, HexGrid}

  typedstruct do
    field :tiles, %{{integer(), integer()} => {HexTile.t(), %{}}}, default: %{}
  end

  @type tile :: HexTile.t()
  @type grid :: t()
  @type coords :: {integer(), integer()}
  @type coordlike :: tile | coords

  @type axial_offset :: {-1..1, -1..1}
  @type diag_offset :: {1, -2} | {2, -1} | {1, 1} | {-1, 2} | {-2, 1} | {-1, -1}
  @type offset_directions ::
          :top | :topleft | :topright | :bottom | :bottomleft | :bottomright | :left | :right

  defguard is_grid(item) when is_struct(item, HexGrid)
  defguard is_tile(item) when is_struct(item, HexTile)
  defguard is_coords(item) when is_tuple(item) and tuple_size(item) == 2
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

  @spec init_tile(coordlike, grid) :: tile
  defp init_tile(tile, grid) when is_coordlike(tile) and is_grid(grid) do
    coords = coords_from(tile)

    {old, {newtile, _}} =
      Map.get_and_update(grid.tiles, coords, fn cv ->
        {cv, {HexTile.new(coords), %{}}}
      end)

    newtile
  end

  @spec put_data(coordlike, map(), grid) :: grid
  @doc "TODO"
  def put_data(tile, state, grid)
      when is_coordlike(tile) and is_map(state) and is_grid(grid) do
    # TODO: clean this mess up and use init_tile
    coords = coords_from(tile)
    {t, ts} = Map.get_lazy(grid.tiles, coords, fn -> {HexTile.new(coords), %{}} end)
    newstate = Map.put(grid.tiles, coords, {t, Map.merge(ts, state)})
    %HexGrid{grid | tiles: newstate}
  end

  # insert_new

  @spec add(coordlike, coordlike) :: tile
  @doc "TODO"
  def add(a, b) when is_coordlike(a) and is_coordlike(b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)
    HexTile.new({q1 + q2, r1 + r2})
  end

  @spec length(coordlike) :: integer
  def length(a) when is_coordlike(a) do
    tile = HexTile.new(a)
    round((abs(tile.q) + abs(tile.r) + abs(tile.s)) / 2)
  end

  @spec sub(coordlike, coordlike) :: tile
  @doc "TODO"
  def sub(a, b) when is_coordlike(a) and is_coordlike(b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)
    HexTile.new({q1 - q2, r1 - r2})
  end

  # Starts at upper left tile and goes clockwise
  @grid_vectors [{0, -1}, {1, -1}, {1, 0}, {0, 1}, {-1, 1}, {-1, 0}]

  # Starts at rightmost tile and goes counterclockwise
  @grid_vectors_alt [{1, 0}, {1, -1}, {0, -1}, {-1, 0}, {-1, 1}, {0, 1}]

  @spec get_neighbor(coordlike, axial_offset) :: tile
  @doc "TODO"
  def get_neighbor(tile, offset) when is_coordlike(tile) and offset in @grid_vectors do
    add(tile, offset)
  end

  @spec get_neighbors(coordlike) :: [tile]
  @doc "TODO"
  def get_neighbors(tile) when is_coordlike(tile) do
    for direction <- @grid_vectors, into: [] do
      get_neighbor(tile, direction)
    end
  end

  @grid_diagonal_vectors [{1, -2}, {2, -1}, {1, 1}, {-1, 2}, {-2, 1}, {-1, -1}]

  @spec get_diagonal_neighbor(tile, diag_offset) :: tile
  @doc "TODO"
  def get_diagonal_neighbor(tile, offset)
      when is_coordlike(tile) and offset in @grid_diagonal_vectors do
    add(tile, offset)
  end

  @spec get_diagonal_neighbor(tile, offset_directions) :: tile
  def get_diagonal_neighbor(tile, direction)
      when is_coordlike(tile) and direction in @grid_diagonal_vectors do
    case direction do
      :top -> {1, -2}
      :topright -> {2, -1}
      :bottomright -> {1, 1}
      :bottom -> {-1, 2}
      :bottomleft -> {-2, 1}
      :topleft -> {-1, -1}
    end
    |> add(tile)
  end

  @rotate_directions [:left, :right]

  @spec rotate(tile, tile, atom()) :: tile
  @doc "TODO"
  def rotate(tile, around, direction)
      when is_coordlike(tile)
      when is_coordlike(around)
      when is_atom(direction)
      when direction in @rotate_directions do
    tile = HexTile.new(tile)
    around = HexTile.new(around)

    case direction do
      :left -> {-tile.r, -tile.s, -tile.q}
      :right -> {-tile.s, -tile.q, -tile.r}
    end
    |> HexTile.new()
  end

  # TODO: distances
  # TODO: pathfinding
  # (eastar, https://github.com/wkhere/eastar/blob/master/lib/examples/geo.ex)

  # put_tile(grid, {q, r})
  # put_tile(grid, tile)
  # get_tile(grid, {q, r})
end
