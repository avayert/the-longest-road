defmodule Catan.Player do
  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
    field :id, String.t(), default: :rand.uniform(1_000_000)
    # field :color, integer(), default: 0 # do random hsv to rgb
  end
end
