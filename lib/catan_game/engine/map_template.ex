defmodule Catan.Engine.MapTemplate do
  @moduledoc false

  @callback name() :: String.t()
  @callback player_count() :: Range.t()
  # @callback template() :: [any()]
  @callback generate(opts :: keyword()) :: any()
end

defmodule Catan.Engine.MapTemplateTile do
  use TypedStruct

  typedstruct do
  end

  use Accessible
end
