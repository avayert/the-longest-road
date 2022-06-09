defmodule Catan.Engine.HexTile do
  @moduledoc """
  Represents a hexagon tile.  Basically a glorified coordinate.
  """
  use Bitwise
  use TypedStruct

  typedstruct do
    field :q, integer(), enforce: true
    field :r, integer(), enforce: true
    field :s, integer()
  end

  @type tile :: t()

  @type axial_coords :: {q :: integer(), r :: integer()}
  @type cubic_coords :: {q :: integer(), r :: integer(), s :: integer()}

  @type coordlike :: tile | axial_coords | cubic_coords

  @type axial_offset :: {-1..1, -1..1}
  @type diag_offset :: {1, -2} | {2, -1} | {1, 1} | {-1, 2} | {-2, 1} | {-1, -1}
  @type grid_orientation :: :pointy | :flat
  @type offset_directions ::
          :top
          | :topleft
          | :topright
          | :bottom
          | :bottomleft
          | :bottomright
          | :left
          | :right

  defguard is_tile(item) when is_struct(item, __MODULE__)
  defguard is_axial_coords(item) when tuple_size(item) == 2
  defguard is_cubic_coords(item) when tuple_size(item) == 3
  defguard is_coords(item) when is_axial_coords(item) or is_cubic_coords(item)
  defguard is_coordlike(item) when is_tile(item) or is_coords(item)
  defguard is_coordlike(i1, i2) when is_coordlike(i1) and is_coordlike(i2)
  defguard is_coordlike(i1, i2, i3) when is_coordlike(i1, i2) and is_coordlike(i3)

  @spec coords_from(coordlike) :: axial_coords
  @doc "Get the coordinates from a coordlike"
  def coords_from(%__MODULE__{q: q, r: r}), do: {q, r}
  def coords_from(item) when is_axial_coords(item), do: item
  def coords_from({q, r, _s} = item) when is_cubic_coords(item), do: {q, r}

  ## Initializers

  @spec new(tile) :: tile
  @doc "TODO"
  def new(%__MODULE__{} = tile), do: tile

  @spec new(axial_coords) :: tile
  def new({q, r}) when is_integer(q) and is_integer(r) do
    new({q, r, -q - r})
  end

  @spec new(cubic_coords) :: tile
  def new({q, r, s})
      when is_integer(q) and is_integer(r) and is_integer(s) and q + r + s == 0 do
    %__MODULE__{q: q, r: r, s: s}
  end

  @spec new(q :: integer(), r :: integer()) :: tile
  def new(q, r), do: new({q, r})

  @spec new(q :: integer(), r :: integer(), s :: integer()) :: tile
  def new(q, r, s)
      when is_integer(q) and is_integer(r) and is_integer(s) and q + r + s == 0 do
    new({q, r, s})
  end

  @spec is_valid(tile) :: boolean()
  def is_valid(tile) when is_struct(tile, __MODULE__) do
    tile.q + tile.r + tile.s == 0
  end

  ## Math functions

  @spec add(coordlike, coordlike) :: tile
  @doc "TODO"
  def add(a, b) when is_coordlike(a, b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)
    new({q1 + q2, r1 + r2})
  end

  @spec sub(coordlike, coordlike) :: tile
  @doc "TODO"
  def sub(a, b) when is_coordlike(a, b) do
    {q1, r1} = coords_from(a)
    {q2, r2} = coords_from(b)
    new({q1 - q2, r1 - r2})
  end

  @spec scale(coordlike, pos_integer()) :: tile
  @doc "TODO aka mul()"
  def scale(a, k) when is_coordlike(a) and is_integer(k) and k > 0 do
    {q, r} = coords_from(a)
    new({q * k, r * k})
  end

  @spec length(coordlike) :: integer
  @doc "TODO"
  def length(a) when is_coordlike(a) do
    tile = new(a)
    round((abs(tile.q) + abs(tile.r) + abs(tile.s)) / 2)
  end

  @spec distance(coordlike, coordlike) :: integer
  @doc "TODO"
  def distance(a, b) when is_coordlike(a, b) do
    a = new(a)
    b = new(b)
    round((abs(a.q - b.q) + abs(a.r - b.r) + abs(a.s - b.s)) / 2)
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
  @grid_orientations [:flat, :pointy]

  @spec get_diagonal_neighbor(tile, offset_directions, grid_orientation) :: tile
  def get_diagonal_neighbor(tile, direction, orientation \\ :pointy)
      when is_coordlike(tile)
      when direction in @grid_offset_directions
      when orientation in @grid_orientations do
    #
    case orientation do
      :flat ->
        case direction do
          :top -> {1, -2}
          :topright -> {2, -1}
          :bottomright -> {1, 1}
          :bottom -> {-1, 2}
          :bottomleft -> {-2, 1}
          :topleft -> {-1, -1}
        end

      :pointy ->
        case direction do
          :topright -> {1, -2}
          :right -> {2, -2}
          :bottomright -> {1, 1}
          :bottomleft -> {-1, 2}
          :left -> {-2, 1}
          :topleft -> {-1, -1}
        end
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
    tile = new(tile)
    around = new(around)

    # TODO
    # This is kinda dumb and bad i could just
    # do math a few times instead of recursing
    case direction do
      :left -> {-tile.r, -tile.s, -tile.q}
      :right -> {-tile.s, -tile.q, -tile.r}
    end
    |> new()
    |> rotate(around, direction, turns - 1)
  end

  @spec rotate(tile, tile, atom(), 0) :: tile
  def rotate(tile, _around, _direction, 0) do
    tile |> new()
  end

  # TODO: distances
  # TODO: pathfinding
  # (eastar, https://github.com/wkhere/eastar/blob/master/lib/examples/geo.ex)

  @spec axial_to_evenr(tile) :: tile
  def axial_to_evenr(hex) when is_tile(hex) do
    col = (hex.q + (hex.r + (hex.r &&& 1))) |> div(2)
    {col, hex.r} |> new()
  end

  ########################
  # TODO: ????????????????
  # @spec evenr_to_axial(tile) :: {integer(), integer()}
  # def evenr_to_axial(hex = %HexTile{}) do
  #   q = (hex.col - (hex.row + (hex.row &&& 1))) |> div(2)
  #   {q, hex.row}
  # end
end
