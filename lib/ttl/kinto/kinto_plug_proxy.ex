defmodule Ttl.KintoPlugProxy do
  import Plug.Conn
  use HTTPoison.Base

  # TODO - persistent connection pool

  def init(opts), do: opts

  # copied from phx
  defp ensure_resp_content_type(%{resp_headers: resp_headers} = conn, content_type) do
    if List.keyfind(resp_headers, "content-type", 0) do
      conn
    else
      content_type = content_type <> "; charset=utf-8"
      %{conn | resp_headers: [{"content-type", content_type}|resp_headers]}
    end
  end

  # copied from phx and added halt
  defp send_resp(conn, default_status, default_content_type, body) do
    conn
    |> ensure_resp_content_type(default_content_type)
    |> send_resp(conn.status || default_status, body)
    |> halt
  end

  def call(conn, _opts) do
    [_ | uri] = conn.path_info
    uri = uri |> Enum.join("/")
    url = "http://localhost:8888/v1/#{uri}"

    # TODO - extra json encode / decode here
    # TODO - not forwarding on any of the headers for etag/match
    # IO.inspect conn.req_headers
    kinto_token = conn.private.plug_session["user_id"]
    base64_auth = "Basic " <> Base.encode64("kinto_token:#{kinto_token}")
    headers=["Content-Type": "application/json", "Authorization": base64_auth]
    options = []
    #options=[hackney: [basic_auth: {"kinto_token", kinto_token}]]

    #IO.inspect conn.body_params
    #IO.inspect conn.request_path

    # intercept and modify batch queries as they send the default header
    body = case conn.method do
             "POST" ->
                 if "batch" in conn.path_info do
                   put_in(conn.body_params, ["defaults", "headers", "Authorization"], base64_auth)
                 else
                   conn.body_params
                 end
               _ -> conn.body_params
           end |> Poison.encode!
    res = request!(conn.method, url, body, headers, options)
    send_resp(conn, res.status_code || 200, "application/json", res.body)

  end
end
