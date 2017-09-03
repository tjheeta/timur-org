defmodule Ttl.Accounts.PlugAuth do
  import Plug.Conn

  def init(opts), do: opts

  """
  Sets private values for user_id and kinto_token to be used
  """
  def call(conn, _opts) do
    # Authenticated assigned by login after /sessions/:token
    # See session controller
    conn =
      case get_session(conn, "authenticated") do
        true ->
          # TODO - kinto token == user_id
          user_id = get_session(conn, "user_id")
          conn
          |> configure_session(renew: true)
          |> put_private(:user_id, user_id)
          |> put_private(:kinto_token, user_id)

        nil ->
          case check_for_api_auth(conn) do
            {true, user_id, token} ->
              conn
              |> put_private(:user_id, user_id)
              |> put_private(:kinto_token, token)
              |> put_private(:from_api, true)
            _ -> conn
          end
    end
    resource_auth(conn)
  end

  def resource_auth(conn) do
    cond do
      # authenticated via session
      conn.private.plug_session["authenticated"] == true -> conn

      # api key is set - allow access to everything
      # a lot of endpoints may expect user id to be set
      # let it fail for now
      conn.private[:kinto_token] != nil -> conn

      # Unauthenticated allowed to see /
      conn.request_path in ["/"] -> conn

      # Unauthenticated allowed to login or get a session
      String.starts_with?(conn.request_path, "/sessions") -> conn

      true -> halt_forbidden(conn, "Need to be logged in")
    end
  end

  def empty?(x) do
    x == nil || x == "" || x == []
  end

  # TODO - change kinto token from being the user.id
  def check_for_api_auth(conn) do
    api_key = get_req_header(conn, "x-api-key") |> Enum.at(0)
    client_id = get_req_header(conn, "x-api-client") |> Enum.at(0)
    if empty?(api_key) || empty?(client_id) do
      {false, nil, nil}
    else
      case Ttl.Accounts.get_user_by_apikey!(api_key) do
        nil -> {false,nil, nil}
        user ->
          if user.id == client_id do
            {true, user.id, user.id}
          else
            {false, nil, nil}
          end
      end
    end
  end

  # TODO:
  # how do we expire all user sessions
  # or only ensure one user session?
  # how do we rotate the keys to avoid hijack?
  def login(conn, user) do
    conn
    |> put_session(:user_id, user.id)
    |> put_session(:current_user, user.email)
    |> put_session(:authenticated, true)
  end

  def logout(conn) do
    conn |> configure_session(drop: true)
  end

  def halt_forbidden(conn, error) do
    conn
    |> send_resp(403, error)
    |> halt
  end
end
