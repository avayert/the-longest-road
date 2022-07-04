defmodule Catan.Engine do
  @moduledoc false

  defmodule Player do
    use TypedStruct

    typedstruct do
      field :name, String.t(), enforce: true
      # field :color, integer()
    end
  end
end
