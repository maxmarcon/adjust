defmodule Mix.Tasks.Tablecopy.Teardown do
  @moduledoc """
  Deletes the source and destination tables.

  ```
  mix tablecopy.teardown
  ```
  """
  use Mix.Task

  @impl Mix.Task

  @shortdoc "Delete source and destination tables"
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
      "DROP TABLE #{source_table}",
      []
    )

    IO.puts("\"#{source_table}\" table on database #{source_db} deleted")

    Postgrex.query!(
      DestDB,
      "DROP TABLE #{dest_table}",
      []
    )

    IO.puts("\"#{dest_table}\" table on database #{dest_db} deleted")
  end
end
