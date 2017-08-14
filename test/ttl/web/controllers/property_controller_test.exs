defmodule Ttl.Web.PropertyControllerTest do
  use Ttl.Web.ConnCase

  alias Ttl.Things

  @create_attrs %{key: "some key", value: "some value"}
  @update_attrs %{key: "some updated key", value: "some updated value"}
  @invalid_attrs %{key: nil, value: nil}

  def fixture(:property) do
    {:ok, property} = Things.create_property(@create_attrs)
    property
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, property_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Properties"
  end

  test "renders form for new properties", %{conn: conn} do
    conn = get conn, property_path(conn, :new)
    assert html_response(conn, 200) =~ "New Property"
  end

  test "creates property and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, property_path(conn, :create), property: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == property_path(conn, :show, id)

    conn = get conn, property_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Property"
  end

  test "does not create property and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, property_path(conn, :create), property: @invalid_attrs
    assert html_response(conn, 200) =~ "New Property"
  end

  test "renders form for editing chosen property", %{conn: conn} do
    property = fixture(:property)
    conn = get conn, property_path(conn, :edit, property)
    assert html_response(conn, 200) =~ "Edit Property"
  end

  test "updates chosen property and redirects when data is valid", %{conn: conn} do
    property = fixture(:property)
    conn = put conn, property_path(conn, :update, property), property: @update_attrs
    assert redirected_to(conn) == property_path(conn, :show, property)

    conn = get conn, property_path(conn, :show, property)
    assert html_response(conn, 200) =~ "some updated key"
  end

  test "does not update chosen property and renders errors when data is invalid", %{conn: conn} do
    property = fixture(:property)
    conn = put conn, property_path(conn, :update, property), property: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Property"
  end

  test "deletes chosen property", %{conn: conn} do
    property = fixture(:property)
    conn = delete conn, property_path(conn, :delete, property)
    assert redirected_to(conn) == property_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, property_path(conn, :show, property)
    end
  end
end
