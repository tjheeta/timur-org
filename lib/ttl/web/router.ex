defmodule Ttl.Web.Router do
  use Ttl.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/", Ttl.Web do
    pipe_through [:browser, Ttl.Accounts.PlugAuth] 

    resources "/users", UserController
    resources "/documents", DocumentController
    resources "/objects", ObjectController
    resources "/tags", TagController
    resources "/properties", PropertyController
    resources "/agenda", AgendaController
    resources "/sessions", SessionController, only: [:new, :create, :show]
    resources "/sessions", SessionController, only: [:delete], singleton: true
    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Ttl.Web do
  #   pipe_through :api
  # end
end
