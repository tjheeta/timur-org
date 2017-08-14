defmodule Ttl.Web.ObjectControllerTest do
  use Ttl.Web.ConnCase

  alias Ttl.Things

  @create_attrs %{blob: "some blob", closed: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, content: "some content", deadline: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, defer_count: 42, level: 42, min_time_needed: 42, path: [], permissions: 42, priority: "some priority", scheduled: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, state: "some state", time_left: 42, time_spent: 42, title: "some title", version: 42}
  @update_attrs %{blob: "some updated blob", closed: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, content: "some updated content", deadline: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, defer_count: 43, level: 43, min_time_needed: 43, path: [], permissions: 43, priority: "some updated priority", scheduled: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, state: "some updated state", time_left: 43, time_spent: 43, title: "some updated title", version: 43}
  @invalid_attrs %{blob: nil, closed: nil, content: nil, deadline: nil, defer_count: nil, level: nil, min_time_needed: nil, path: nil, permissions: nil, priority: nil, scheduled: nil, state: nil, time_left: nil, time_spent: nil, title: nil, version: nil}

  def fixture(:object) do
    {:ok, object} = Things.create_object(@create_attrs)
    object
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, object_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Objects"
  end

  test "renders form for new objects", %{conn: conn} do
    conn = get conn, object_path(conn, :new)
    assert html_response(conn, 200) =~ "New Object"
  end

  test "creates object and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, object_path(conn, :create), object: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == object_path(conn, :show, id)

    conn = get conn, object_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Object"
  end

  test "does not create object and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, object_path(conn, :create), object: @invalid_attrs
    assert html_response(conn, 200) =~ "New Object"
  end

  test "renders form for editing chosen object", %{conn: conn} do
    object = fixture(:object)
    conn = get conn, object_path(conn, :edit, object)
    assert html_response(conn, 200) =~ "Edit Object"
  end

  test "updates chosen object and redirects when data is valid", %{conn: conn} do
    object = fixture(:object)
    conn = put conn, object_path(conn, :update, object), object: @update_attrs
    assert redirected_to(conn) == object_path(conn, :show, object)

    conn = get conn, object_path(conn, :show, object)
    assert html_response(conn, 200) =~ "some updated content"
  end

  test "does not update chosen object and renders errors when data is invalid", %{conn: conn} do
    object = fixture(:object)
    conn = put conn, object_path(conn, :update, object), object: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Object"
  end

  test "deletes chosen object", %{conn: conn} do
    object = fixture(:object)
    conn = delete conn, object_path(conn, :delete, object)
    assert redirected_to(conn) == object_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, object_path(conn, :show, object)
    end
  end
end
