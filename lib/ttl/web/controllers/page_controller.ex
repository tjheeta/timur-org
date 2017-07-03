defmodule Ttl.Web.PageController do
  use Ttl.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
