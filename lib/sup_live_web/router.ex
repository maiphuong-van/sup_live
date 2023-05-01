defmodule SupLiveWeb.Router do
  use SupLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SupLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SupLiveWeb do
    pipe_through :browser

    live "/old_stuff", IndexLive
    live "/", ProcessesLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", SupLiveWeb do
  #   pipe_through :api
  # end
end
