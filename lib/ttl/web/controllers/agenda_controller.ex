defmodule Ttl.Web.AgendaController do
  use Ttl.Web, :controller

  alias Ttl.Things

  def index(conn, _params) do
    objects = Things.list_objects()
    objects = Things.get_todo_objects("1")
    render(conn, "index.html", objects: objects)
  end
end
