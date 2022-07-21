defmodule Catan.LobbyInfo do
  use TypedStruct

  typedstruct enforce: true do
    field :id, String.t()
    field :name, String.t(), default: "placeholder"
    field :players, non_neg_integer(), default: 0
    field :expansion, module(), default: nil
    field :scenarios, [module()], default: []
    field :map_template, any(), default: nil
  end

  def from_state(state) do
    fields =
      for field <- Map.from_struct(state) do
        case field do
          {:id, _} -> field
          {:players, players} -> {:players, length(players)}
          {:expansion, _} -> field
          {:scenarios, _} -> field
          {:map_template, _} -> field
          _ -> {:ignore, :ignore}
        end
      end

    struct(__MODULE__, fields)
  end
end
