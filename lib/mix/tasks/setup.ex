defmodule Mix.Tasks.Tablecopy.Setup do
  @moduledoc """
  Creates the source and destination tables.

  ```
  mix tablecopy.setup
  ```
  """
  use Mix.Task

  @impl Mix.Task

  @table_schema "(a INT, b INT, c INT)"

  @shortdoc "Create source and destination tables"
  def run(_args) do
    Application.ensure_all_started(:tablecopy)

    source_config = Application.get_env(:tablecopy, :source_db)
    {:ok, source_table} = Keyword.fetch(source_config, :table)
    {:ok, source_db} = Keyword.fetch(source_config, :database)

    dest_config = Application.get_env(:tablecopy, :dest_db)
    {:ok, dest_table} = Keyword.fetch(dest_config, :table)
    {:ok, dest_db} = Keyword.fetch(dest_config, :database)

    Postgrex.query!(
      SourceDB,
      "CREATE TABLE IF NOT EXISTS #{source_table} #{@table_schema}",
      []
    )

    IO.puts("\"#{source_table}\" table on database #{source_db} created")

    Postgrex.query!(
      DestDB,
      "CREATE TABLE IF NOT EXISTS #{dest_table} #{@table_schema}",
      []
    )

    IO.puts("\"#{dest_table}\" table on database #{dest_db} created")
  end
end
