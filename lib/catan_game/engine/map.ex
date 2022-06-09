defmodule Catan.Engine.GameMap do
  @moduledoc """
  TODO
  """

  use GenServer

  alias Catan.Engine.{HexGrid, HexTile}

  import HexTile,
    only: [
      is_coordlike: 1,
      # is_coords: 1,
      is_tile: 1,
      coords_from: 1
    ]

  @type tile :: HexTile.t()
  @type grid :: HexGrid.t()
  @type coords :: HexTile.axial_coords()
  @type coordlike :: HexTile.coordlike()
  @type vector :: HexTile.axial_offset()

  @type via_tuple() :: {:via, atom(), {atom(), String.t()}}

  defmodule State do
    use TypedStruct

    typedstruct do
      field :tilemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :edgemap, HexGrid.grid(), default: HexGrid.new(:pointy)
      field :cornermap, HexGrid.grid(), default: HexGrid.new(:flat)
    end
  end

  @spec via(String.t()) :: via_tuple()
  defp via(id) do
    {:via, Registry, {MapManager, id}}
  end

  # genserver callbacks

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
      HexTile.new(tile)
      |> HexTile.scale(2)
      |> HexTile.add(vector)

    data = HexGrid.get_data(state.edgemap, tile)

    {:reply, {tile, data}, state}
  end

  # private functions

  # public api

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

  @spec get_edge(tile :: coordlike, vector :: vector) :: {tile, map()}
  @doc "TODO"
  def get_edge(tile, vector) when is_coordlike(tile) and vector in @grid_vectors do
    # Translate tile vector into bigmap coordinates
    # it should just be as easy as tile*2 + vector
    # I HOPE

    ############
    #
    # GODDAMN IT I NEED A REGISTRY AND VIA LOOKUPS
    #
    ############

    GenServer.call(__MODULE__, {:get_edge, tile, vector})
  end

  @spec get_corner(tile :: coordlike(), vector :: vector) :: any()
  @doc "TODO"
  def get_corner(tile, vector) when is_coordlike(tile) and vector in @grid_vectors do
    # same deal as above just with the flat top orientation
  end

  def shutdown do
    GenServer.cast(__MODULE__, {:terminate})
  end
end
