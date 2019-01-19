defmodule Tablecopy.Application do
  use Application

  @impl Application

  def start(_type, _args) do
    children = [
      {SourceConnectionPool,
       {DBConnection.ConnectionPool, :start_link,
        [
          {Postgrex.Protocol,
           Keyword.merge(
             Application.get_env(:tablecopy, :source_db),
             types: Postgrex.DefaultTypes,
             name: SourceDB
           )}
        ]}, :permanent, 5000, :worker, [DBConnection.ConnectionPool]},
      {DestConnectionPool,
       {DBConnection.ConnectionPool, :start_link,
        [
          {Postgrex.Protocol,
           Keyword.merge(
             Application.get_env(:tablecopy, :dest_db),
             types: Postgrex.DefaultTypes,
             name: DestDB
           )}
        ]}, :permanent, 5000, :worker, [DBConnection.ConnectionPool]},
      {Plug.Cowboy,
       scheme: :http, plug: Tablecopy.Webserver.Router, options: [port: server_port()]}
    ]

    opts = [strategy: :one_for_one, name: Tablecopy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp server_port() do
    config = Application.get_env(:tablecopy, Webserver)
    {:ok, port} = Keyword.fetch(config, :port)
    port
  end
end
