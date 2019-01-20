# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :tablecopy, :source_db,
  # hostname of the source DB
  hostname: "localhost",
  # source DB user
  username: "homestead",
  # source DB password
  password: "secret",
  # source database name
  database: "foo",
  # source table name
  table: "source"

config :tablecopy, :dest_db,
  # hostname of the destination DB
  hostname: "localhost",
  # destination DB user
  username: "homestead",
  # destination DB password
  password: "secret",
  # desitnation DB name
  database: "bar",
  # destination database table
  table: "dest"

config :tablecopy, Tablecopy,
  # how many entries to generate in the source table
  entries: 1_000_000,
  # how many rows will be kept in memory when generating the entries, copying or serving them (i.e. the size of a chunk)
  buffer: 500

config :tablecopy, Webserver, port: 8080
