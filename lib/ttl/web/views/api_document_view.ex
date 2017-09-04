defmodule Ttl.Web.ApiDocumentView do
  use Ttl.Web, :view
  alias Ttl.Web.ApiDocumentView

  def render("index.json", %{documents: documents}) do
    %{data: render_many(documents, ApiDocumentView, "document.json")}
  end

  def render("index.json", %{document: document}) do
    %{data: render_one(document, ApiDocumentView, "document.json")}
  end

  def render("show.json", %{document: document}) do
    %{:text => document, :attachments => nil}
  end

  def render("document.json", %{api_document: document}) do
    %{
      id: document["id"],
      name: document["name"]
     }
  end

  def render("sync.json", %{data: data}) do
    %{
     "ok" => data["ok"],
     "id" => data["id"],
     "lastModified" => data["last_modified"],
     "conflicts" => data["conflicts"],
     "errors" => data["errors"],
     "skipped" => length(data["skipped"]),
     "published" => length(data["published"]),
     "resolved" => data["resolved"]
    }
  end

end
