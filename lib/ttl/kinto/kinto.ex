defmodule Kinto do
  #http://docs.kinto-storage.org/en/stable/api/1.x/index.html#cheatsheet
  use HTTPoison.Base

  @expected_fields ~w(
    code details
  )

  def query_batch(token, url, method, data) do
    # http://docs.kinto-storage.org/en/stable/api/1.x/batch.html
    options=[hackney: [basic_auth: {"kinto_token", token}]]
    headers=["Content-Type": "application/json"]

    defaults = %{method: method, path: url}
    requests = Enum.map(data, fn(x) ->
      # if there is an id in the data add it to the path
      case Map.get(x, :id) do
        nil -> %{body: %{data: x}}
        id -> %{body: %{data: x}, path: url <> "/" <> id}
      end
    end)
    datastr = %{defaults: defaults, requests: requests}
    |> Poison.encode!

    res = post!("/batch", datastr, headers, options)
    res.body
  end

  def query_patch!(token, url, data) do
    options=[hackney: [basic_auth: {"kinto_token", token}]]
    headers=["Content-Type": "application/json"]
    # url, body, headers, options
    datastr = Poison.encode!(%{data: data})
    res=patch!(url, datastr, headers, options)
    res.body
  end

  def query_put!(token, url, data) do
    options=[hackney: [basic_auth: {"kinto_token", token}]]
    headers=["Content-Type": "application/json"]
    # url, body, headers, options
    datastr = Poison.encode!(%{data: data})
    res=put!(url, datastr, headers, options)
    res.body
  end

  def query_post!(token, url, data) do
    options=[hackney: [basic_auth: {"kinto_token", token}]]
    headers=["Content-Type": "application/json"]
    datastr = Poison.encode!(%{data: data})
    # url, body, headers, options
    res = post!(url, datastr, headers, options)
    res.body
  end

  def query_get!(token, url) do
    options=[hackney: [basic_auth: {"kinto_token", token}]]
    res = get!(url, [], options)
    case res.status_code do
      404 -> nil
      _ -> res.body
    end
  end

  def process_url(url) do
    "http://localhost:8888/v1" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    #|> Map.take(@expected_fields)
    #|> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
