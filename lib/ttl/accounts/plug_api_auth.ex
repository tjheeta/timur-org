defmodule Ttl.Accounts.PlugApiAuth do
  import Plug.Conn

  def init(opts), do: opts

  # TODO - ratelimiting
  def call(conn, _opts) do
    api_key = get_req_header(conn, "x-api-key") |> Enum.at(0)
    client_id = get_req_header(conn, "x-api-client") |> Enum.at(0)
    case Ttl.Accounts.get_user_by_apikey!(api_key) do
      nil -> halt_forbidden(conn,"Not authorized")
      user ->
        if user.id != client_id do
          halt_forbidden(conn,"Not authorized")
        else
          conn
        end
    end
  end

  def halt_forbidden(conn, error) do
    conn
    |> send_resp(403, error)
    |> halt
  end
end
