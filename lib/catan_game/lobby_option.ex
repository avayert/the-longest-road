defmodule Catan.LobbyOption do
  use TypedStruct

  @type option_type :: :range | :select | :toggle | :text

  typedstruct enforce: true do
    field :name, atom()
    field :display_name, String.t()
    field :event, String.t() | false, default: nil
    field :type, atom()
    field :values, Enum.t(), default: []
    field :default, any(), default: nil
  end

  use Accessible

  def new(opts) do
    struct!(__MODULE__, opts)
    |> ensure_fields()
  end

  defp ensure_fields(lobbyopts) do
    case lobbyopts.event do
      nil -> struct!(lobbyopts, event: Atom.to_string(lobbyopts.name))
      _ -> lobbyopts
    end
  end
end
