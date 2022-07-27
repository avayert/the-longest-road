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

  @spec from_state(state :: Catan.Lobby.State.t()) :: t()
  def from_state(state) when is_struct(state, Catan.Lobby.State) do
    fields =
      for field <- Map.from_struct(state) do
        case field do
          {:id, _} -> field
          {:name, _} -> field
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
