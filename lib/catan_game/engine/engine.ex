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

  defmodule Tile do
    use TypedStruct

    typedstruct do
      field :coords, {integer(), integer()}, enforce: true
      field :resource, atom(), default: nil
    end
  end

  defmodule GameSettings do
    use TypedStruct

    typedstruct do
      # refer to image in figjam
    end
  end

  defmodule GameStats do
    use TypedStruct

    typedstruct do
    end
  end
end
