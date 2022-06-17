defmodule Catan.Engine.GameMap do
  @moduledoc """
  TODO
  """

  use GenServer, restart: :transient

  require Integer

  alias Catan.Engine.{HexGrid, HexTile}

  import HexTile,
    only: [
      is_coordlike: 1,
      is_coordlike: 3,
      # is_coords: 1,
      is_tile: 1,
      coords_from: 1
    ]

  import Integer,
    only: [
      is_even: 1,
      is_odd: 1
    ]

  @type tile :: HexTile.t()
  @type grid :: HexGrid.t()
  @type coords :: HexTile.axial_coords()
  @type coordlike :: HexTile.coordlike()
  @type vector :: HexTile.axial_offset()

  @type map_id :: String.t()
  @type via_tuple() :: {:via, module(), {module(), String.t()}}

  defmodule State do
    use TypedStruct

    typedstruct do
      field :tilemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :edgemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :cornermap, HexGrid.grid(), default: HexGrid.new(:flat)
    end
  end

  ## GenServer callbacks

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %State{}, opts)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:terminate}, state) do
    {:stop, :shutdown, state}
  end

  @impl true
  def handle_call({:get_tile, coords}, _from, state) do
    reply = {HexTile.new(coords), HexGrid.get_data(state.tilemap, coords)}
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:get_edge, tile, vector}, _from, state) do
    tile =
      tile
      |> to_bigmap_tile()
      |> HexTile.add(vector)

    data = HexGrid.get_data(state.edgemap, tile)

    {:reply, {tile, data}, state}
  end

  @impl true
  def handle_call({:get_corner, tile, vector}, _from, state) do
    tile =
      tile
      |> to_bigmap_tile()
      |> HexTile.add(vector)

    data = HexGrid.get_data(state.cornermap, tile)

    {:reply, {tile, data}, state}
  end

  @impl true
  def handle_call({:get_corner, t1, t2, t3}, _from, state) do
    # TODO: check if they're all properly adjacent
    tile1 = to_bigmap_tile(t1)
    tile2 = to_bigmap_tile(t2)
    tile3 = to_bigmap_tile(t3)

    tile =
      case HexTile.get_common_neighbors([tile1, tile2, tile3]) do
        [tile | _] -> tile
        [] -> nil
      end

    data =
      if tile do
        HexGrid.get_data(state.cornermap, tile)
      end

    {:reply, {tile, data}, state}
  end

  ## Private functions

  @spec via(String.t()) :: via_tuple()
  defp via(id) do
    {:via, Registry, {MapManager, id}}
  end

  defp to_bigmap_tile(tile) when is_coordlike(tile) do
    tile |> HexTile.new() |> HexTile.scale(2)
  end

  # "Translate bigmap coordinates to an object in the real map"
  defp to_tilemap_object(tile, :edgemap) when is_coordlike(tile) do
    {q, r} = coords_from(tile)
    {qn, rn} = {rem(q, 2), rem(r, 2)}

    # tiles: q and r are even
    # edges: q and r cannot both be even
    case {qn, rn} do
      {0, 0} -> {:tile, HexTile.new(qn, rn)}
      _ -> {:edge, nil}
    end
  end

  defp to_tilemap_object!(tile, :cornermap) when is_coordlike(tile) do
    {q, r} = coords_from(tile)
    # this is going to be scuffed as hell
    # basically everything is aligned diagonally
    # if we just subtract vectors favorably, we'll reach the inner ring
    # if we land on a tile diagional to 0 (a vector tile), we're good
    # if we land on a neighbor to one, we're not
    nil
  end

  defp parity?(n1, n2) when is_integer(n1) and is_integer(n2) do
    is_even(n1 + n2)
  end

  ## Public api

  @spec get_tile(String.t(), coords) :: {tile, state :: map()}
  @doc "TODO"
  def get_tile(map_id, coords) when is_coordlike(coords) do
    GenServer.call(via(map_id), {:get_tile, coords_from(coords)})
  end

  @spec get_tile(String.t(), tile) :: {tile, state :: map()}
  def get_tile(map_id, tile) when is_tile(tile) do
    get_tile(map_id, coords_from(tile))
  end

  # These ones are a bit more complicated.  Edges and corners are offset
  # from the center tile so referencing them becomes odd.  I could reference
  # them like offsets or i could do something else
  #
  # Edges and corners could be a vector around a tile translated to the
  # doublemap coord or they could just be relative offsets

  @grid_vectors [{0, -1}, {1, -1}, {1, 0}, {0, 1}, {-1, 1}, {-1, 0}]

  @spec get_edge(map_id, tile :: coordlike, vector :: vector) :: {tile, map()}
  @doc "TODO"
  def get_edge(id, tile, vector) when is_coordlike(tile) and vector in @grid_vectors do
    GenServer.call(via(id), {:get_edge, tile, vector})
  end

  @spec get_corner(map_id, tile :: coordlike(), vector :: vector) :: {tile, map()}
  @doc "TODO"
  def get_corner(id, tile, vector) when is_coordlike(tile) and vector in @grid_vectors do
    GenServer.call(via(id), {:get_corner, tile, vector})
  end

  @spec get_corner(map_id, tile, tile, tile) :: {tile, map()}
  def get_corner(id, tile1, tile2, tile3) when is_coordlike(tile1, tile2, tile3) do
    GenServer.call(via(id), {:get_corner, tile1, tile2, tile3})
  end

  def shutdown(id) do
    GenServer.cast(via(id), {:terminate})
  end
end
