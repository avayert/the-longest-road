defmodule CatanWeb.Plugs.PlayerSessionPlug do
  import Plug.Conn

  @cookie_name "player_profile"

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> fetch_session()
    |> fetch_cookies(signed: [@cookie_name])
    |> load_player_data()
  end

  def load_player_data(conn) do
    data =
      case conn.cookies do
        %{@cookie_name => data} -> refresh_player(data)
        _ -> new_player()
      end

    conn
    |> put_resp_cookie(@cookie_name, data, sign: true)
    |> fetch_cookies(signed: [@cookie_name])
    |> put_session(@cookie_name, data)
  end

  @titles ~w(Mr Ms Captain Professor Doctor Admiral Lord DJ)

  defp new_player() do
    <<l::utf8, rest::binary>> = MnemonicSlugs.generate_slug(1)
    name = Enum.random(@titles) <> " " <> String.upcase(<<l>>) <> rest
    %Catan.Engine.Player{name: name}
  end

  defp refresh_player(player) when is_struct(player, Catan.Engine.Player) do
    struct!(Catan.Engine.Player, player |> Map.from_struct())
  end
end
