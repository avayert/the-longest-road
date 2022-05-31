defmodule Catan.Engine.Hexes.HexTile do
  use TypedStruct

  typedstruct do
    field :q, integer(), enforce: true
    field :r, integer(), enforce: true
    field :type, atom()
    field :data, map(), default: %{}
  end

  @type coords :: {integer(), integer()}

  @spec new(q :: integer(), r :: integer()) :: t()
  def new(q, r), do: new({q, r})

  @spec new(coords) :: t()
  def new(coords), do: new(coords, nil, %{})

  @spec new(coords, atom(), map()) :: t()
  def new({q, r}, type, data)
      when is_integer(q) and is_integer(r) and is_atom(type) and is_map(data) do
    %__MODULE__{q: q, r: r, type: type, data: data}
  end

  # def update(tile, opts) do
  #   opts
  # end

  @spec update(t(), :type, atom()) :: t()
  def update(tile, :type, data) do
    %__MODULE__{tile | type: data}
  end

  @spec update(t(), :data, map()) :: t()
  def update(tile, :data, data) do
    %__MODULE__{tile | data: data}
  end

  @spec s(t()) :: integer()
  def s(tile) do
    -tile.q - tile.r
  end
end
