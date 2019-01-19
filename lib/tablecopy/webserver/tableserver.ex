defmodule Tablecopy.Webserver.Tableserver do
  import Plug.Conn

  def init(_opts) do
    source_config = Application.get_env(:tablecopy, :source_db)
    dest_config = Application.get_env(:tablecopy, :dest_db)
    tablecopy_config = Application.get_env(:tablecopy, Tablecopy)

    %{
      source_db: source_config[:database],
      source_table: source_config[:table],
      dest_db: dest_config[:database],
      dest_table: dest_config[:table],
      buffer: tablecopy_config[:buffer]
    }
  end

  def call(%{params: %{"db" => db, "table" => table}} = conn, %{
        source_db: source_db,
        source_table: source_table,
        dest_db: dest_db,
        dest_table: dest_table,
        buffer: buffer
      })
      when (db == source_db and table == source_table) or (db == dest_db and table == dest_table) do
    db_conn_pool =
      if db == source_db do
        SourceDB
      else
        DestDB
      end

    {:ok, conn} =
      Postgrex.transaction(
        db_conn_pool,
        fn db_conn ->
          reading_query =
            Postgrex.prepare!(
              db_conn,
              "",
              "COPY #{table} TO STDOUT (FORMAT csv)"
            )

          reading_stream = Postgrex.stream(db_conn, reading_query, [], max_rows: buffer)

          Enum.reduce_while(reading_stream, send_chunked(conn, :ok), fn %Postgrex.Result{
                                                                          rows: rows
                                                                        },
                                                                        conn ->
            case chunk(conn, Enum.join(rows)) do
              {:ok, conn} ->
                {:cont, conn}

              {:error, :closed} ->
                {:halt, conn}
            end
          end)
        end
      )

    conn
  end

  def call(conn, _) do
    send_resp(conn, 404, "Not found")
  end
end
