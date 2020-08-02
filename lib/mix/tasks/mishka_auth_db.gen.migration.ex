defmodule Mix.Tasks.MishkaAuth.Db.Gen.Migration do
  @shortdoc "Generates Guardian.DB's migration"

  @moduledoc """
  Generates the required MishkaAuth's database migration.
  """
  use Mix.Task

  import Mix.Ecto
  import Mix.Generator
  alias MishkaAuth.Client.Users.ClientToken

  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.migration")

    repos = parse_repo(args)

    Enum.each(repos, fn repo ->
      ensure_repo(repo, args)
      path = Ecto.Migrator.migrations_path(repo)

      source_path =
        :mishka_auth
        |> Application.app_dir()
        |> Path.join("priv/templates/migration.exs.eex")

      generated_file =
        EEx.eval_file(source_path,
          module_prefix: app_module(),
          db_prefix: prefix()
        )

      target_file = Path.join(path, "#{timestamp()}_guardiandb.exs")
      create_directory(path)
      create_file(target_file, generated_file)
    end)
  end

  defp app_module do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end


  def prefix do
    :mishka_auth
    |> Application.fetch_env!(:db_host)
    |> Keyword.get(:prefix, nil)
  end


  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
