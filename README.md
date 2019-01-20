# Tablecopy

## Description

Runs a workflow that:

1. Fills a table *source* with the integers from 1 to a given value (default: 1_000_000), alongside with their modulo 3 and modulo 5.
1. Copies the content of *source* to a table *dest* located in a different database. 
1. The content of both tables is made available as CSV by an embedded Web server, and transfeered using chunked encoding.

## Installation

You will need Elixir and Postgres. After you clone the repository, run:

```
mix deps.get
mix compile
```
## Configuration

Configuration is in `config/config.exs`. See the comment in the file for which parameters can be configured and their meanings.

At the very least, you will need to add the `username` and `password` required to log in to the databases.
However, you don't need to create the tables, the program can do it by itself. See the next section for details.

By default, the application will create 1_000_000 rows in a table `source` in database `foo` and then copy them to
the table `dest` in the database `bar`. At most 500 entries will be kept in memory at any time.

## How to run

Once everything is configured, you can create the source and destination tables by running:

`mix tablecopy.setup`

Then you can run the whole workflow (filling source table, copy to destination and web server) by running:

`mix tablecopy.run`

After the program runs, the script will output the HTTP endpoints under which the tables can be accessed.

See `mix help tablecopy.run` for options on how to skip single steps.

## Cleaning up

If you want to remove the tables, for example because you want to rerun the workflow, just run:

`mix tablecoy.teardown`

This will delete both the source and destination tables.





