defmodule Catan.Utils do
  @moduledoc false

  @spec update_map(map :: map(), options :: keyword()) :: map()
  @doc "Updates a map or struct with options from a keyword list"
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
end
