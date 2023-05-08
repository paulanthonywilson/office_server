defmodule OfficeServerWeb.Router do
  use OfficeServerWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:auth)
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {OfficeServerWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", OfficeServerWeb do
    pipe_through(:browser)
    live "/", OfficeListLive
    live "/boxes/:device_id", OfficeLive
  end

  if Mix.env() == :test do
    defp auth(conn, _), do: conn
  else
    defp auth(conn, _opts) do
      Plug.BasicAuth.basic_auth(conn,
        username: OfficeServer.Authentication.auth_username(),
        password: OfficeServer.Authentication.auth_password()
      )
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", OfficeServerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:office_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: OfficeServerWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
