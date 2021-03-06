defmodule Ttl.Web.SessionController do
  use Ttl.Web, :controller

  alias Ttl.Accounts.User

  def new(conn, params) do
     changeset = User.changeset(%User{}, params)
     render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => params}) do
     case Ttl.Accounts.User.create_session(params) do
       {:ok, _} ->
         conn
         |> put_flash(:info, "We sent you a link. Please check your inbox.")
         |> redirect(to: page_path(conn, :index))
       {:error, changeset} ->
         render(conn, "new.html", changeset: changeset)
     end
  end

  def show(conn, %{"id" => access_token}) do
    case Ttl.Accounts.User.verify_session(access_token) do
      {:error, _} ->
        conn
        |> put_flash(:error, "Access token not found or expired.")
        |> redirect(to: page_path(conn, :index))
      {:ok, user} ->
        conn
        |> Ttl.Accounts.PlugAuth.login(user)
        |> put_flash(:info, "Welcome #{user.email}")
        |> redirect(to: page_path(conn, :index))
    end
  end


  def delete(conn, _params) do
    conn
    |> Ttl.Accounts.PlugAuth.logout
    |> put_flash(:info, "User logged out.")
    |> redirect(to: page_path(conn, :index))
  end
end
