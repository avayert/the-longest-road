defmodule Catan.Lobby do
  use TypedStruct

  alias Catan.Utils

  @type game_speed :: :none | :slow | :normal | :fast | :turbo
  # TODO: figure out a system to get times for different state directives

  typedstruct do
    field :id, String.t(), enforce: true

    field :players, [any()], default: []
    field :ready_states, %{struct() => boolean()}, default: %{}
    field :game_started, boolean(), default: false

    field :lobby_name, String.t(), default: "New Lobby"
    field :private_lobby, boolean(), default: true
    field :game_speed, game_speed(), default: :normal
    field :max_players, pos_integer(), default: 4
    field :hand_limit, pos_integer(), default: 7
    field :win_vp, pos_integer(), default: 10

    field :game_mode, module(), default: Catan.Engine.GameMode.Standard
    field :expansion, module(), default: nil
    field :scenarios, [module()], default: []
    # TODO: map stuff
    field :map_template, any(), default: nil
  end

  use Accessible

  def new(id, opts \\ []) do
    %__MODULE__{id: id} |> Utils.update_map(opts)
  end

  @spec set_settings(state :: t(), opts :: keyword()) :: t()
  def set_settings(state, opts) do
    Utils.update_map(state, opts)
  end

  @spec ready?(state :: t()) :: boolean()
  def ready?(state) do
    Enum.all?(state.ready_states, fn {_, v} -> v end)
  end
end
