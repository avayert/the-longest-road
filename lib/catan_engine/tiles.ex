defmodule Catan.Engine.HexTile do
  use TypedStruct

  typedstruct do
    field :q, integer(), enforce: true
    field :r, integer(), enforce: true
    field :type, atom()
    field :data, map()
  end

  def new(q, r, type \\ nil, data \\ nil)
      when is_integer(q) and is_integer(r) do
    %__MODULE__{q: q, r: r, type: type, data: data}
  end
end

defmodule Catan.Engine.HexGrid do
  alias Catan.Engine.HexTile
  use Bitwise
  use TypedStruct

  typedstruct do
    field :tiles, %{tuple() => HexTile.t()}, default: %{}
  end

  def new() do
    %__MODULE__{}
  end

  def new_hexagon(radius) do
    # TODO
    new()
  end

  defp get_s(%HexTile{q: q, r: r}) do
    -q - r
  end

  # TODO: make args actually work right
  def axial_to_evenr(hex) do
    col = (hex.q + (hex.r + (hex.r &&& 1))) |> div(2)
    {col, hex.r}
  end

  # TODO: make args actually work right
  def evenr_to_axial(hex) do
    q = (hex.col - (hex.row + (hex.row &&& 1))) |> div(2)
    {q, hex.row}
  end

  # TODO: evenq variants (switch which var the ops are on)

  # TODO
  def get_tile_axial(grid, %HexTile{} = hex) do
    Map.get(grid.tiles, hex)
  end

  # Starts at rightmost tile and goes counterclockwise
  @grid_vectors {{1, 0}, {1, -1}, {0, -1}, {-1, 0}, {-1, 1}, {0, 1}}

  def get_neighbors(grid, hex) do
  end

  def get_neighbor(grid, hex, {q, r}) do
  end

  def get_diagonal_neighbor(grid, direction) do
  end

  # TODO: rotation?
  # TODO: distances
  # TODO: pathfinding (eastar, https://github.com/wkhere/eastar/blob/master/lib/examples/geo.ex)

  # put_tile(grid, {q, r})
  # put_tile(grid, tile)
  # get_tile(grid, {q, r})
end
