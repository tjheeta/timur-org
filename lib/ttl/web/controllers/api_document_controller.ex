defmodule Ttl.Web.ApiDocumentController do
  use Ttl.Web, :controller

  alias Ttl.Things

  # TODO - fallback
  ##action_fallback Ttl.Web.FallbackController

  def index(conn, _params) do
    documents = Ttl.Things.kinto_list_documents(conn.private[:kinto_token])
    render(conn, "index.json", documents: documents["data"])
  end

  def create(conn, params ) do
    %Plug.Upload{content_type: content_type,
                 filename: filename,
                 path: path} = params["file"]
    attrs = %{:kinto_token => conn.private[:kinto_token], :mode => "default"}
    out = Ttl.Parse.Import.import(path, attrs)

    documents = Ttl.Things.kinto_list_documents(conn.private[:kinto_token])
    render(conn, "index.json", documents: documents["data"])
  end

  def show(conn, %{"id" => id}) do
    attrs = %{:kinto_token => conn.private[:kinto_token], :add_id => true}
    docstr = Ttl.Parse.Export.export(id, attrs)
    render(conn, "show.json", document: docstr)
  end

  # TODO - error conditions
  def delete(conn, %{"id" => id}) do
    Ttl.Things.kinto_delete_document(conn.private[:kinto_token], id)
    send_resp(conn, :no_content, "")
#    with {:ok, %User{}} <- Accounts.delete_user(user) do
#    end
  end

# def update(conn, %{"id" => id, "user" => user_params}) do
#   user = Accounts.get_user!(id)

#   with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
#     render(conn, "show.json", user: user)
#   end
# end

end
