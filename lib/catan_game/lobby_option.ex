defmodule Catan.LobbyOption do
  use TypedStruct

  @type option_type :: :range | :select | :toggle | :text

  typedstruct enforce: true do
    field :name, atom()
    field :display_name, String.t()
    field :type, atom()
    field :values, Enum.t(), default: []
    field :default, any(), default: nil
  end

  use Accessible

  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
