defmodule Catan.Engine.Hexes do
  use Bitwise

  alias Catan.Engine.Hexes.{HexGrid, HexTile}

  @type tile :: HexTile.t()
  @type coords :: {integer(), integer()}

  @spec add(tile, tile) :: tile
  def add(a = %HexTile{}, b = %HexTile{}) do
    HexTile.new({a.q + b.q, a.r + b.r})
  end

  @spec add(tile, tile) :: tile
  def sub(a = %HexTile{}, b = %HexTile{}) do
    HexTile.new({a.q - b.q, a.r - b.r})
  end

  @spec s(tile) :: integer()
  def s(%HexTile{q: q, r: r}) do
    -q - r
  end

  @spec axial_to_evenr(tile) :: coords
  def axial_to_evenr(hex = %HexTile{}) do
    col = (hex.q + (hex.r + (hex.r &&& 1))) |> div(2)
    {col, hex.r}
  end

  # TODO: make tuple version

  ########################
  # TODO: ????????????????
  # @spec evenr_to_axial(tile) :: {integer(), integer()}
  # def evenr_to_axial(hex = %HexTile{}) do
  #   q = (hex.col - (hex.row + (hex.row &&& 1))) |> div(2)
  #   {q, hex.row}
  # end

  ########################
  # TODO: evenq variants (switch which var the ops are on)
end
