defmodule Ttl.Web.DocumentControllerTest do
  use Ttl.Web.ConnCase

  alias Ttl.Things

  @create_attrs %{name: "some name", objects: []}
  @update_attrs %{name: "some updated name", objects: []}
  @invalid_attrs %{name: nil, objects: nil}

  def fixture(:document) do
    {:ok, document} = Things.create_document(@create_attrs)
    document
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, document_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Documents"
  end

  test "renders form for new documents", %{conn: conn} do
    conn = get conn, document_path(conn, :new)
    assert html_response(conn, 200) =~ "New Document"
  end

  test "creates document and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, document_path(conn, :create), document: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == document_path(conn, :show, id)

    conn = get conn, document_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Document"
  end

  test "does not create document and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, document_path(conn, :create), document: @invalid_attrs
    assert html_response(conn, 200) =~ "New Document"
  end

  test "renders form for editing chosen document", %{conn: conn} do
    document = fixture(:document)
    conn = get conn, document_path(conn, :edit, document)
    assert html_response(conn, 200) =~ "Edit Document"
  end

  test "updates chosen document and redirects when data is valid", %{conn: conn} do
    document = fixture(:document)
    conn = put conn, document_path(conn, :update, document), document: @update_attrs
    assert redirected_to(conn) == document_path(conn, :show, document)

    conn = get conn, document_path(conn, :show, document)
    assert html_response(conn, 200) =~ "some updated name"
  end

  test "does not update chosen document and renders errors when data is invalid", %{conn: conn} do
    document = fixture(:document)
    conn = put conn, document_path(conn, :update, document), document: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Document"
  end

  test "deletes chosen document", %{conn: conn} do
    document = fixture(:document)
    conn = delete conn, document_path(conn, :delete, document)
    assert redirected_to(conn) == document_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, document_path(conn, :show, document)
    end
  end
end
