defmodule Catan.Utils do
  @moduledoc "Miscellaneous utility functions"

  # @spec update_map(struct :: struct(), options :: keyword()) :: struct()
  # def update_map(struct, options)
  #     when is_struct(struct) and (is_list(options) or is_map(options)) do
  #   #
  #   struct!(struct, update_map(%{}, options))
  # end

  @spec update_map(map :: map(), options :: keyword()) :: map()
  @doc "Updates a map with options from a keyword list"
  def update_map(map, options)
      when is_map(map) and (is_list(options) or is_map(options)) do
    #
    for {k, v} <- options, reduce: map do
      acc -> Map.replace(acc, k, v)
    end
  end

  @ignored_id_chars ~W(i I l O)

  @spec random_id(num :: pos_integer()) :: String.t()
  @doc "Generate a random [a-zA-Z] string (default length of 5)"
  def random_id(num \\ 5) when is_number(num) and num > 0 do
    Stream.concat(?a..?z, ?A..?Z)
    |> Stream.reject(fn ch -> ch in @ignored_id_chars end)
    # do not judge me you have no such authority
    |> Enum.shuffle()
    |> Enum.take_random(num)
    |> List.to_string()

    # TODO: check registry where needed to make sure id doesnt exist
    #       likely unnecessary but you know, that 1-in-1M chance
  end

  @spec weighted_random(keyword(pos_integer())) :: atom()
  def weighted_random(items) do
    # https://elixirforum.com/t/weight-based-random-sampling/23345/4

    accumulated_weights =
      items
      |> Enum.sort(&(elem(&1, 1) < elem(&2, 1)))
      |> Enum.scan(fn {k, w}, {_, w_sum} -> {k, w + w_sum} end)

    {_, max} = List.last(accumulated_weights)
    random_value = Enum.random(1..max)

    Enum.reduce_while(accumulated_weights, random_value, fn {k, w}, r ->
      if r <= w, do: {:halt, k}, else: {:cont, r}
    end)
  end

  @spec get_stacktrace() :: String.t()
  @spec get_stacktrace(drop :: non_neg_integer()) :: String.t()
  def get_stacktrace(drop \\ 2) do
    "Stacktrace for #{inspect(self())}:\n" <>
      (Process.info(self(), :current_stacktrace)
       |> elem(1)
       |> Enum.drop(drop)
       |> Exception.format_stacktrace())
  end

  @type result :: any()

  @spec unwrap({atom(), result()}) :: result()
  def unwrap({op, other}) when is_atom(op) do
    other
  end

  @spec expand_kwlist([{term(), integer()}]) :: [term()]
  def expand_kwlist(list) do
    Enum.flat_map(list, fn {item, count} ->
      List.duplicate(item, count)
    end)
  end
end
