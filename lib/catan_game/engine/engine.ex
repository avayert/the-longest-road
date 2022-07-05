defmodule Catan.Engine do
  @moduledoc false

  defmodule Player do
    use TypedStruct

    typedstruct do
      field :name, String.t(), enforce: true
      field :id, String.t(), default: :rand.uniform(1000000)
      # field :color, integer(), default: 0 # do random hsv to rgb
    end
  end
end
