defmodule Tablecopy.Webserver.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/dbs/:db/:table", to: Tablecopy.Webserver.Tableserver)

  match(_, do: send_resp(conn, 404, "Not found"))
end
