defmodule Catan.Engine.Hexes.HexTile do
  use TypedStruct

  typedstruct do
    field :q, integer(), enforce: true
    field :r, integer(), enforce: true
    field :s, integer()
  end

  @type coords :: {q :: integer(), r :: integer()}

  @spec new(q :: integer(), r :: integer()) :: t()
  def new(q, r), do: new({q, r})

  @spec new(t()) :: t()
  def new(%__MODULE__{} = tile), do: tile

  @spec new(coords) :: t()
  def new({q, r}) when is_integer(q) and is_integer(r) do
    %__MODULE__{q: q, r: r, s: -q - r}
  end
end
