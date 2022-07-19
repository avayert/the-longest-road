defmodule Catan.Engine.Maps.Standard do
  @behaviour Catan.Engine.MapTemplate

  alias Catan.Engine.{HexGrid, HexTile}
  import Catan.Utils, only: [expand_kwlist: 1]

  @resource_tiles [
    forest: 4,
    fields: 4,
    pasture: 4,
    mountains: 3,
    hills: 3,
    desert: 1
  ]

  @resource_counters [
    {2, 1},
    {3, 2},
    {4, 2},
    {5, 2},
    {6, 2},
    {8, 2},
    {9, 2},
    {10, 2},
    {11, 2},
    {12, 1}
  ]

  @harbors [
    generic: 4,
    lumber: 1,
    grain: 1,
    wool: 1,
    ore: 1,
    brick: 1
  ]

  @impl true
  def name(), do: "Standard"

  @impl true
  def player_count(), do: 2..4

  @impl true
  def generate(opts \\ []) do
    HexGrid.new()
    |> place_resources(opts)
    |> place_numbers(opts)
    |> place_harbors(opts)
    |> align_harbors(opts)
  end

  defp place_resources(grid, _opts) do
    tiles =
      expand_kwlist(@resource_tiles)
      |> Enum.shuffle()

    HexTile.spiral({0, 0}, 2)
    |> Enum.zip_reduce(tiles, grid, fn coord, tile, grid ->
      HexGrid.put_data(grid, coord, %{terrain: tile})
    end)
  end

  defp place_numbers(grid, _opts) do
    counters =
      expand_kwlist(@resource_counters)
      |> Enum.shuffle()

    newtiles =
      grid.tiles
      |> Enum.reduce({grid.tiles, 0}, fn
        {coord, %{terrain: :desert} = tstate}, {acc, index} ->
          acc = Map.put(acc, coord, tstate)
          {acc, index}

        {coord, %{terrain: _} = tstate}, {acc, index} ->
          num = Enum.at(counters, index)
          acc = Map.put(acc, coord, Map.put(tstate, :number, num))
          {acc, index + 1}
      end)
      |> elem(0)

    put_in(grid, [:tiles], newtiles)
  end

  def place_harbors(grid, _opts) do
    harbors =
      expand_kwlist(@harbors)
      |> Enum.shuffle()
      |> Enum.map_intersperse(nil, & &1)
      # randomly offset the harbor ring
      |> List.insert_at(round(:rand.uniform()) - 1, nil)

    HexTile.ring({0, 0}, 3)
    |> Enum.zip_reduce(harbors, grid, fn
      _coord, nil, grid ->
        grid

      coord, harbor, grid ->
        HexGrid.put_data(grid, coord, %{harbor: harbor})
    end)
  end

  defp align_harbors(grid, _opts) do
    grid
  end
end
