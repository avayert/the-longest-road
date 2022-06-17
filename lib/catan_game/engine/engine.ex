defmodule Catan.Engine do
  @moduledoc false

  defmodule Player do
    use TypedStruct

    typedstruct do
      field :name, String.t()
      field :color, integer()
      field :hand, list()
    end
  end

  defmodule GameStats do
    use TypedStruct

    typedstruct do
    end
  end
end
