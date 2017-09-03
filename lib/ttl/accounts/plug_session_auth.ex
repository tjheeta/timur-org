defmodule Ttl.Accounts.PlugSessionAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    #IO.inspect conn
    # This should have been assigned by login
    #IO.inspect fetch_session(conn)
    case get_session(conn, :user_id) do
      nil -> assign(conn, :current_user, nil)
      _ -> conn |> configure_session(renew: true)
    end
    resource_auth(conn)
  end

  def resource_auth(conn) do
    case conn.private.plug_session["current_user"]  do
      nil ->
        if conn.request_path in ["/"] or String.starts_with?(conn.request_path, "/sessions") do
          conn
        else
          halt_forbidden(conn, "Need to be logged in")
        end
      _ ->
        conn
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
