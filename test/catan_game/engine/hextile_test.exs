defmodule HexTileTest do
  use ExUnit.Case, async: true
  # doctest Catan.Engine.Hexes.HexTile

  alias Catan.Engine.Hexes.HexTile

  test "create a tile" do
    assert HexTile.new(0, 0) == %HexTile{q: 0, r: 0, s: 0}
    assert HexTile.new(-2, 3) == %HexTile{q: -2, r: 3, s: -1}
    assert HexTile.new({1, 2}) == %HexTile{q: 1, r: 2, s: -3}
  end

  test "create a bad tile" do
    assert_raise FunctionClauseError, fn ->
      HexTile.new(:a, :b)
    end
  end

  test "validate tiles" do
    assert HexTile.new(-1, -1) |> HexTile.is_valid()
    assert %HexTile{q: 1, r: 2, s: -3} |> HexTile.is_valid()
    refute %HexTile{q: 1, r: 2, s: 3} |> HexTile.is_valid()
  end
end
