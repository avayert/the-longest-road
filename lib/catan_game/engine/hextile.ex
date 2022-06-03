defmodule Catan.Engine.Hexes.HexTile do
  use TypedStruct

  typedstruct do
    field :q, integer(), enforce: true
    field :r, integer(), enforce: true
    field :s, integer()
  end

  @type axial_coords :: {q :: integer(), r :: integer()}
  @type cubic_coords :: {q :: integer(), r :: integer(), s :: integer()}

  @spec new(t()) :: t()
  def new(%__MODULE__{} = tile), do: tile

  @spec new(axial_coords) :: t()
  def new({q, r}), do: new({q, r, -q - r})

  @spec new(cubic_coords) :: t()
  def new({q, r, s})
      when is_integer(q) and is_integer(r) and is_integer(s) and q + r + s == 0 do
    %__MODULE__{q: q, r: r, s: s}
  end

  @spec new(q :: integer(), r :: integer()) :: t()
  def new(q, r), do: new({q, r})

  @spec new(q :: integer(), r :: integer(), s :: integer()) :: t()
  def new(q, r, s)
      when is_integer(q) and is_integer(r) and is_integer(s) and q + r + s == 0 do
    new({q, r, s})
  end

  @spec is_valid(t()) :: boolean()
  def is_valid(tile) when is_struct(tile, __MODULE__) do
    tile.q + tile.r + tile.s == 0
  end
end
