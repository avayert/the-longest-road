defmodule HexGridTest do
  use ExUnit.Case, async: true
  # doctest Catan.Engine.HexGrid

  alias Catan.Engine.{HexGrid, HexTile}

  test "create a grid" do
    assert HexGrid.new() == %HexGrid{}
  end

  test "test coord extraction" do
    assert HexTile.new(2, 3) |> HexTile.coords_from() == {2, 3}
    assert {-1, -2} |> HexTile.coords_from() == {-1, -2}
  end

  test "put and get data in a grid tile" do
    coords = {1, 2}
    data1 = %{type: :a, data: :b}
    grid = HexGrid.new() |> HexGrid.put_data({1, 2}, data1)

    assert data1 == HexGrid.get_data(grid, coords)

    data2 = %{type: :c}
    grid = HexGrid.put_data(HexGrid.new(), {1, 2}, data2)

    assert data2 == HexGrid.get_data(grid, coords)
  end

  test "clear tile data in a grid" do
    coords = {-2, 2}
    data = %{:type => :bonk, "stuff" => "whatever"}
    grid1 = HexGrid.new()
    grid3 = HexGrid.put_data(grid1, coords, data) |> HexGrid.clear_data(coords)

    assert HexGrid.get_data(grid3, coords) == HexGrid.get_data(grid1, coords)
  end

  # test "update tile data in a grid" do
  #   coords = {6, 0}
  #   data = %{:type => :bonk, "stuff" => "incorrect"}
  #   grid1 = HexGrid.put_data(HexGrid.new, coords, data)
  #   data2 = %{"stuff" => "correct"}
  #   grid2 = HexGrid.update_data(grid1, coords, data2)

  #   assert Map.merge(data1, data2) == HexGrid.get_data(grid2, coords)
  # end

  @tag :hexmath
  test "add tiles" do
  end

  @tag :hexmath
  test "subtract tiles" do
  end

  @tag :hexmath
  test "get tile neighbors" do
  end

  @tag :hexmath
  test "get diagonal tile neighbors" do
  end

  @tag :hexmath
  test "rotate a tile" do
  end
end
