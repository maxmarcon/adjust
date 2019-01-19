defmodule Tablecopy do
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
        ]}, :permanent, 5000, :worker, [DBConnection.ConnectionPool]}
    ]

    opts = [strategy: :one_for_one, name: Tablecopy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
