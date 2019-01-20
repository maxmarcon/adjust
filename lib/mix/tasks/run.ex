defmodule Mix.Tasks.Tablecopy.Run do
  @moduledoc """
  This task initializes the source table with content, then copies the content of the source
  table tot the destination table. Afterwards, the content of the tables is available as CSV via an
  embedded Web server at the following endpints:

  ```
  /dbs/[source_db]/[source_table]
  /dbs/[dest_db]/[dest_table]
  ```

  where `source_db`, `source_table`, `dest_db` and `dest_table` are the names of the
  source and destination databases and tables, respectively.

  ```
  mix tablecopy.run
  ```

  ## Command line options:

  * `--no-init` - Skip initialization of the source table
  * `--no-copy` - Skip copy of content from the source to the destination table
  * `--halt` - Stop the application right after copying the content. The Web server won't be available.
  """
  use Mix.Task

  @col_names "(a, b, c)"

  @shortdoc "Copies tables and starts a web server"
  def run(args) do
    Application.ensure_all_started(:tablecopy)

    {options, _, invalid} =
      OptionParser.parse(args,
        strict: [init: :boolean, copy: :boolean, halt: :boolean]
      )

    if Enum.any?(invalid) do
      raise "Unknown command line options: " <> Enum.join(Keyword.keys(invalid), ",")
    end

    config = get_config()

    start_time = Time.utc_now()

    if Keyword.get(options, :init, true) do
      fill_source_table(config)
    end

    if Keyword.get(options, :copy, true) do
      copy_source_to_destination_table(config)
    end

    msec = Time.diff(Time.utc_now(), start_time, :millisecond)

    IO.puts("Total time taken: #{msec} milliseconds")

    unless Keyword.get(options, :halt, false) do
      IO.puts("The tables are now available under:")
      IO.puts("localhost:#{config[:port]}/dbs/#{config[:source_db]}/#{config[:source_table]}")
      IO.puts("localhost:#{config[:port]}/dbs/#{config[:dest_db]}/#{config[:dest_table]}")

      Process.sleep(:infinity)
    end
  end

  defp get_config() do
    tablecopy_config = Application.get_env(:tablecopy, Tablecopy)
    source_config = Application.get_env(:tablecopy, :source_db)
    dest_config = Application.get_env(:tablecopy, :dest_db)
    webserver_config = Application.get_env(:tablecopy, Webserver)

    {:ok, entries} = Keyword.fetch(tablecopy_config, :entries)
    {:ok, buffer} = Keyword.fetch(tablecopy_config, :buffer)
    {:ok, source_db} = Keyword.fetch(source_config, :database)
    {:ok, source_table} = Keyword.fetch(source_config, :table)
    {:ok, dest_db} = Keyword.fetch(dest_config, :database)
    {:ok, dest_table} = Keyword.fetch(dest_config, :table)
    {:ok, port} = Keyword.fetch(webserver_config, :port)

    %{
      entries: entries,
      buffer: buffer,
      source_db: source_db,
      source_table: source_table,
      dest_db: dest_db,
      dest_table: dest_table,
      port: port
    }
  end

  defp fill_source_table(%{entries: entries, buffer: buffer, source_table: source_table}) do
    IO.puts("Filling table #{source_table} with #{entries} entries")

    Enum.map(1..entries, &{&1, rem(&1, 3), rem(&1, 5)})
    |> Stream.chunk_every(buffer)
    |> Enum.each(fn tuples ->
      values =
        Enum.join(
          for(
            i <- 0..(length(tuples) - 1),
            do: "($#{i * 3 + 1}, $#{i * 3 + 2}, $#{i * 3 + 3})"
          ),
          ","
        )

      Postgrex.query!(
        SourceDB,
        "INSERT INTO #{source_table} #{@col_names} VALUES #{values}",
        Enum.flat_map(tuples, &Tuple.to_list/1)
      )

      {last_written, _, _} = List.last(tuples)

      IO.write("Written #{last_written} entries...\r")
    end)

    IO.puts("\ndone!")
  end

  defp copy_source_to_destination_table(%{
         source_table: source_table,
         dest_table: dest_table,
         buffer: buffer
       }) do
    IO.puts("Copying data from table #{source_table} to table #{dest_table}")

    parent_pid = self()

    Task.start_link(fn ->
      Postgrex.transaction(SourceDB, fn conn ->
        reading_query =
          Postgrex.prepare!(
            conn,
            "",
            "COPY #{source_table} TO STDOUT"
          )

        reading_stream = Postgrex.stream(conn, reading_query, [], max_rows: buffer)

        Enum.each(reading_stream, fn %Postgrex.Result{rows: rows} ->
          send(parent_pid, {:rows, rows})
        end)

        send(parent_pid, :done)
      end)
    end)

    Postgrex.transaction(DestDB, fn conn ->
      writing_query =
        Postgrex.prepare!(
          conn,
          "",
          "COPY #{dest_table} FROM STDIN"
        )

      writing_stream = Postgrex.stream(conn, writing_query, [])

      Enum.into(
        Stream.unfold(0, fn cnt ->
          receive do
            {:rows, rows} ->
              cnt = cnt + length(rows)
              IO.write("Copied #{cnt} rows...\r")
              {Enum.join(rows), cnt}

            :done ->
              nil

            _ ->
              raise "Unknown message received"
          end
        end),
        writing_stream
      )
    end)

    IO.puts("\ndone!")
  end
end
