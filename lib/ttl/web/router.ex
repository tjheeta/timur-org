defmodule Ttl.Web.Router do
  use Ttl.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Ttl.Accounts.PlugAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Ttl.Accounts.PlugAuth
  end

  pipeline :kinto do
    plug :fetch_session
    plug :accepts, ["json"]
    #plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Ttl.Accounts.PlugAuth
    plug Ttl.KintoPlugProxy
  end

  # TODO - kinto.js fails if not explicitly /v1
  # Uncaught Error: The remote URL must contain the version: http://10.0.0.175:4000/kintov1
  scope "/v1/", Ttl.Web do
    pipe_through :kinto
    # TODO - just to generate routes which aren't used.
    # KintoPlugProxy does all the forwarding to kinto
    get "/*bla", Nowhere, :index
    post "/*bla", Nowhere, :index
    put "/*bla", Nowhere, :index
    patch "/*bla", Nowhere, :index
    options "/*bla", Nowhere, :index
  end

  scope "/", Ttl.Web do
    pipe_through :browser

    resources "/users", UserController
    resources "/documents", DocumentController
    resources "/objects", ObjectController
    resources "/tags", TagController
    resources "/properties", PropertyController
    resources "/sessions", SessionController, only: [:new, :create, :show]
    resources "/sessions", SessionController, only: [:delete], singleton: true
    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Ttl.Web do
  #   pipe_through :api
  # end
end
