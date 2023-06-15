defmodule ChatWeb.PageController do
  use ChatWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Usuario creado exitosamente.")

    render(conn, "index.html")
  end
end
