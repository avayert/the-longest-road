defmodule Catan.Engine.DirectiveStack do
  @moduledoc false

  alias Catan.Engine.GameMode.Helpers

  defmodule Directive do
    use TypedStruct

    typedstruct do
      field :op, Helpers.directive(), enforce: true
      field :ctx, module()
      field :meta, any()
    end

    def new(op, opts \\ []) do
      struct!(__MODULE__, op ++ opts)
    end
    use Accessible
  end

  @type directive :: Directive.t()

  @type dir_op :: any()

  @type old_directive :: Helpers.directive()
  @type new_directive :: %{
          required(:op) => dir_op(),
          optional(:ctx) => module(),
          optional(:meta) => any()
        }

  ## Struct

  use TypedStruct

  typedstruct do
    field :stack, [new_directive()], default: []
  end

  use Accessible

  ## Functions

  def new do
    %__MODULE__{}
  end

  def new(state) when is_list(state) do
    %__MODULE__{stack: state}
  end

  @dir_opts [:ctx, :meta]

  defp map_opts(opts) do
    Enum.reduce(opts, %{}, fn {k, v}, acc ->
      if k in @dir_opts, do: Map.put(acc, k, v), else: acc
    end)
  end

  @doc "Push a directive onto the stack"
  def push_state(stack, directive, opts \\ [])

  @spec push_state(
          stack :: t(),
          directive :: [old_directive],
          opts :: keyword() | map()
        ) :: t()
  def push_state(stack, [directive], opts) do
    push_state(stack, directive, opts)
  end

  @spec push_state(
          stack :: t(),
          directive :: old_directive(),
          opts :: keyword() | map()
        ) :: t()
  def push_state(stack, directive, opts) do
    update_in(stack, [:stack], fn l ->
      [Map.merge(%{op: directive}, map_opts(opts)) | l]
    end)
  end

  @doc "Pop a directive from the stack, if any"
  @spec pop_state(stack :: t()) :: {new_directive() | nil, t()}
  def pop_state(stack) do
    get_and_update_in(stack.stack, &List.pop_at(&1, 0))
  end

  @spec head(stack :: t()) :: new_directive() | nil
  def head(stack), do: hd(stack.stack)

  @spec tail(stack :: t()) :: [new_directive()] | []
  def tail(stack), do: tl(stack.stack)
end
