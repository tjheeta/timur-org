defmodule Ttl.ThingsTest do
  use Ttl.DataCase

  alias Ttl.Things

  describe "documents" do
    alias Ttl.Things.Document

    @valid_attrs %{name: "some name", objects: []}
    @update_attrs %{name: "some updated name", objects: []}
    @invalid_attrs %{name: nil, objects: nil}

    def document_fixture(attrs \\ %{}) do
      {:ok, document} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Things.create_document()

      document
    end

    test "list_documents/0 returns all documents" do
      document = document_fixture()
      assert Things.list_documents() == [document]
    end

    test "get_document!/1 returns the document with given id" do
      document = document_fixture()
      assert Things.get_document!(document.id) == document
    end

    test "create_document/1 with valid data creates a document" do
      assert {:ok, %Document{} = document} = Things.create_document(@valid_attrs)
      assert document.name == "some name"
      assert document.objects == []
    end

    test "create_document/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Things.create_document(@invalid_attrs)
    end

    test "update_document/2 with valid data updates the document" do
      document = document_fixture()
      assert {:ok, document} = Things.update_document(document, @update_attrs)
      assert %Document{} = document
      assert document.name == "some updated name"
      assert document.objects == []
    end

    test "update_document/2 with invalid data returns error changeset" do
      document = document_fixture()
      assert {:error, %Ecto.Changeset{}} = Things.update_document(document, @invalid_attrs)
      assert document == Things.get_document!(document.id)
    end

    test "delete_document/1 deletes the document" do
      document = document_fixture()
      assert {:ok, %Document{}} = Things.delete_document(document)
      assert_raise Ecto.NoResultsError, fn -> Things.get_document!(document.id) end
    end

    test "change_document/1 returns a document changeset" do
      document = document_fixture()
      assert %Ecto.Changeset{} = Things.change_document(document)
    end
  end

  describe "objects" do
    alias Ttl.Things.Object

    @valid_attrs %{blob: "some blob", closed: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, content: "some content", deadline: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, defer_count: 42, level: 42, min_time_needed: 42, path: [], permissions: 42, priority: "some priority", scheduled: %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}, state: "some state", time_left: 42, time_spent: 42, title: "some title", version: 42}
    @update_attrs %{blob: "some updated blob", closed: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, content: "some updated content", deadline: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, defer_count: 43, level: 43, min_time_needed: 43, path: [], permissions: 43, priority: "some updated priority", scheduled: %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}, state: "some updated state", time_left: 43, time_spent: 43, title: "some updated title", version: 43}
    @invalid_attrs %{blob: nil, closed: nil, content: nil, deadline: nil, defer_count: nil, level: nil, min_time_needed: nil, path: nil, permissions: nil, priority: nil, scheduled: nil, state: nil, time_left: nil, time_spent: nil, title: nil, version: nil}

    def object_fixture(attrs \\ %{}) do
      {:ok, object} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Things.create_object()

      object
    end

    test "list_objects/0 returns all objects" do
      object = object_fixture()
      assert Things.list_objects() == [object]
    end

    test "get_object!/1 returns the object with given id" do
      object = object_fixture()
      assert Things.get_object!(object.id) == object
    end

    test "create_object/1 with valid data creates a object" do
      assert {:ok, %Object{} = object} = Things.create_object(@valid_attrs)
      assert object.blob == "some blob"
      assert object.closed == %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}
      assert object.content == "some content"
      assert object.deadline == %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}
      assert object.defer_count == 42
      assert object.level == 42
      assert object.min_time_needed == 42
      assert object.path == []
      assert object.permissions == 42
      assert object.priority == "some priority"
      assert object.scheduled == %DateTime{calendar: Calendar.ISO, day: 17, hour: 14, microsecond: {0, 6}, minute: 0, month: 4, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2010, zone_abbr: "UTC"}
      assert object.state == "some state"
      assert object.time_left == 42
      assert object.time_spent == 42
      assert object.title == "some title"
      assert object.version == 42
    end

    test "create_object/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Things.create_object(@invalid_attrs)
    end

    test "update_object/2 with valid data updates the object" do
      object = object_fixture()
      assert {:ok, object} = Things.update_object(object, @update_attrs)
      assert %Object{} = object
      assert object.blob == "some updated blob"
      assert object.closed == %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}
      assert object.content == "some updated content"
      assert object.deadline == %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}
      assert object.defer_count == 43
      assert object.level == 43
      assert object.min_time_needed == 43
      assert object.path == []
      assert object.permissions == 43
      assert object.priority == "some updated priority"
      assert object.scheduled == %DateTime{calendar: Calendar.ISO, day: 18, hour: 15, microsecond: {0, 6}, minute: 1, month: 5, second: 1, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2011, zone_abbr: "UTC"}
      assert object.state == "some updated state"
      assert object.time_left == 43
      assert object.time_spent == 43
      assert object.title == "some updated title"
      assert object.version == 43
    end

    test "update_object/2 with invalid data returns error changeset" do
      object = object_fixture()
      assert {:error, %Ecto.Changeset{}} = Things.update_object(object, @invalid_attrs)
      assert object == Things.get_object!(object.id)
    end

    test "delete_object/1 deletes the object" do
      object = object_fixture()
      assert {:ok, %Object{}} = Things.delete_object(object)
      assert_raise Ecto.NoResultsError, fn -> Things.get_object!(object.id) end
    end

    test "change_object/1 returns a object changeset" do
      object = object_fixture()
      assert %Ecto.Changeset{} = Things.change_object(object)
    end
  end

  describe "tags" do
    alias Ttl.Things.Tag

    @valid_attrs %{tag: "some tag"}
    @update_attrs %{tag: "some updated tag"}
    @invalid_attrs %{tag: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Things.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Things.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Things.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Things.create_tag(@valid_attrs)
      assert tag.tag == "some tag"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Things.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, tag} = Things.update_tag(tag, @update_attrs)
      assert %Tag{} = tag
      assert tag.tag == "some updated tag"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Things.update_tag(tag, @invalid_attrs)
      assert tag == Things.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Things.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Things.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Things.change_tag(tag)
    end
  end

  describe "properties" do
    alias Ttl.Things.Property

    @valid_attrs %{key: "some key", value: "some value"}
    @update_attrs %{key: "some updated key", value: "some updated value"}
    @invalid_attrs %{key: nil, value: nil}

    def property_fixture(attrs \\ %{}) do
      {:ok, property} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Things.create_property()

      property
    end

    test "list_properties/0 returns all properties" do
      property = property_fixture()
      assert Things.list_properties() == [property]
    end

    test "get_property!/1 returns the property with given id" do
      property = property_fixture()
      assert Things.get_property!(property.id) == property
    end

    test "create_property/1 with valid data creates a property" do
      assert {:ok, %Property{} = property} = Things.create_property(@valid_attrs)
      assert property.key == "some key"
      assert property.value == "some value"
    end

    test "create_property/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Things.create_property(@invalid_attrs)
    end

    test "update_property/2 with valid data updates the property" do
      property = property_fixture()
      assert {:ok, property} = Things.update_property(property, @update_attrs)
      assert %Property{} = property
      assert property.key == "some updated key"
      assert property.value == "some updated value"
    end

    test "update_property/2 with invalid data returns error changeset" do
      property = property_fixture()
      assert {:error, %Ecto.Changeset{}} = Things.update_property(property, @invalid_attrs)
      assert property == Things.get_property!(property.id)
    end

    test "delete_property/1 deletes the property" do
      property = property_fixture()
      assert {:ok, %Property{}} = Things.delete_property(property)
      assert_raise Ecto.NoResultsError, fn -> Things.get_property!(property.id) end
    end

    test "change_property/1 returns a property changeset" do
      property = property_fixture()
      assert %Ecto.Changeset{} = Things.change_property(property)
    end
  end
end
