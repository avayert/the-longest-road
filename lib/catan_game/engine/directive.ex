defmodule Catan.Engine.Directive do
  use TypedStruct

  require Catan.Engine.GameMode.Helpers

  @type method :: :action | :phase
  @type op :: {method(), atom()}
  @type stack :: [] | [t()]

  typedstruct do
    field :op, op(), enforce: true
    field :ctx, module()
    field :meta, any()
    field :choices, list(), default: []
  end

  # I hate it
  defmacro new(expr) do
    quote do
      with [{_, _} = op | opts] = unquote(expr),
           opts = [ctx: unquote(__CALLER__.module)] ++ opts ++ [op: op] do
        struct!(unquote(__MODULE__), opts)
      end
    end
  end

  # def new_(op, opts \\ [])

  # def new_({_, _} = op, opts) do
  #   new_([op: op], opts)
  # end

  # def new_([op: _] = op, opts) do
  #   struct!(__MODULE__, op ++ opts)
  # end

  # def new_([{_, _} = op], opts) do
  #   new_([op: op], opts)
  # end

  use Accessible
end
