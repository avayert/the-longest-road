defmodule Catan.Engine.Hexes.HexGrid do
  use Bitwise
  use TypedStruct

  alias Catan.Engine.Hexes
  alias Hexes.{HexTile, HexGrid}

  @type tile :: HexTile.t()
  @type grid :: t()
  @type coords :: HexTile.axial_coords()
  @type coordlike :: tile | coords

  @type axial_offset :: {-1..1, -1..1}
  @type diag_offset :: {1, -2} | {2, -1} | {1, 1} | {-1, 2} | {-2, 1} | {-1, -1}
  @type offset_directions ::
          :top | :topleft | :topright | :bottom | :bottomleft | :bottomright | :left | :right

  typedstruct do
    field :tiles, %{coords => map()}, default: %{}
  end

  defguard is_grid(item) when is_struct(item, HexGrid)
  defguard is_tile(item) when is_struct(item, HexTile)
  defguard is_coords(item) when is_tuple(item) and tuple_size(item) == 2
  defguard is_coordlike(item) when is_tile(item) or is_coords(item)
  defguard is_coordlike(i1, i2) when is_coordlike(i1) and is_coordlike(i2)
  defguard is_coordlike(i1, i2, i3) when is_coordlike(i1, i2) and is_coordlike(i2, i3)

  @spec coords_from(coordlike) :: coords
  @doc "Get the coordinates from a coordlike"
  def coords_from(%HexTile{q: q, r: r}), do: {q, r}
  def coords_from({_q, _r} = item) when is_coords(item), do: item

  @spec new() :: t()
  @doc "Create a new HexGrid"
  def new() do
    %__MODULE__{}
  end

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

  @spec add(coordlike, coordlike) :: tile
  @doc "TODO"
  def add(a, b) when is_coordlike(a, b) do
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
  def sub(a, b) when is_coordlike(a, b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)
    HexTile.new({q1 - q2, r1 - r2})
  end

  # Starts at upper left tile and goes clockwise
  @grid_vectors [{0, -1}, {1, -1}, {1, 0}, {0, 1}, {-1, 1}, {-1, 0}]

  # Starts at rightmost tile and goes counterclockwise
  # @grid_vectors_alt [{1, 0}, {1, -1}, {0, -1}, {-1, 0}, {-1, 1}, {0, 1}]

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

  @grid_offset_directions [
    :top,
    :topleft,
    :topright,
    :bottom,
    :bottomleft,
    :bottomright,
    :left,
    :right
  ]

  @spec get_diagonal_neighbor(tile, offset_directions) :: tile
  def get_diagonal_neighbor(tile, direction)
      when is_coordlike(tile) and direction in @grid_offset_directions do
    #
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
  def rotate(tile, around, direction) do
    rotate(tile, around, direction, 1)
  end

  @spec rotate(tile, tile, atom(), pos_integer()) :: tile
  @doc "TODO"
  def rotate(tile, around, direction, turns)
      when is_coordlike(tile, around)
      when is_atom(direction)
      when direction in @rotate_directions
      when turns > 0 do
    #
    tile = HexTile.new(tile)
    around = HexTile.new(around)

    case direction do
      :left -> {-tile.r, -tile.s, -tile.q}
      :right -> {-tile.s, -tile.q, -tile.r}
    end
    |> HexTile.new()
    |> rotate(around, direction, turns - 1)
  end

  @spec rotate(tile, tile, atom(), 0) :: tile
  def rotate(tile, _around, _direction, 0) do
    tile |> HexTile.new()
  end

  # TODO: distances
  # TODO: pathfinding
  # (eastar, https://github.com/wkhere/eastar/blob/master/lib/examples/geo.ex)

  # put_tile(grid, {q, r})
  # put_tile(grid, tile)
  # get_tile(grid, {q, r})
end
