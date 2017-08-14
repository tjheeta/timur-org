defmodule Ttl.Web.PropertyController do
  use Ttl.Web, :controller

  alias Ttl.Things

  def index(conn, _params) do
    properties = Things.list_properties()
    render(conn, "index.html", properties: properties)
  end

  def new(conn, _params) do
    changeset = Things.change_property(%Ttl.Things.Property{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"property" => property_params}) do
    case Things.create_property(property_params) do
      {:ok, property} ->
        conn
        |> put_flash(:info, "Property created successfully.")
        |> redirect(to: property_path(conn, :show, property))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    property = Things.get_property!(id)
    render(conn, "show.html", property: property)
  end

  def edit(conn, %{"id" => id}) do
    property = Things.get_property!(id)
    changeset = Things.change_property(property)
    render(conn, "edit.html", property: property, changeset: changeset)
  end

  def update(conn, %{"id" => id, "property" => property_params}) do
    property = Things.get_property!(id)

    case Things.update_property(property, property_params) do
      {:ok, property} ->
        conn
        |> put_flash(:info, "Property updated successfully.")
        |> redirect(to: property_path(conn, :show, property))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", property: property, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    property = Things.get_property!(id)
    {:ok, _property} = Things.delete_property(property)

    conn
    |> put_flash(:info, "Property deleted successfully.")
    |> redirect(to: property_path(conn, :index))
  end
end
