defmodule Catan.LobbyOption do
  use TypedStruct

  @type option_type :: :range | :select

  typedstruct enforce: true do
    field :name, atom()
    field :display_name, String.t()
    field :type, atom()
    field :values, any(), default: []
    field :default, any(), default: nil
  end

  use Accessible

  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
