defmodule Ttl.Web.ApiDocumentView do
  use Ttl.Web, :view
  alias Ttl.Web.ApiDocumentView

  def render("index.json", %{documents: documents}) do
    %{data: render_many(documents, ApiDocumentView, "document.json")}
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
end
