defmodule KvsWeb.Router do
  use KvsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KvsWeb do
    pipe_through :api
    get "/key/:key", KvsController, :get_key
    put "/key/:key", KvsController, :put_key
    delete "/key/:key", KvsController, :delete_key
    put "/collection/:collection", KvsController, :put_collection
    delete "/collection/:collection", KvsController, :delete_collection
    get "/collection/:collection/key/:key", KvsController, :get_key_from_collection
    put "/collection/:collection/key/:key", KvsController, :put_key_to_collection
    delete "/collection/:collection/key/:key", KvsController, :delete_key_from_collection
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kvs, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: KvsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
