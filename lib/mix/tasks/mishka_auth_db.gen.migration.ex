defmodule Mix.Tasks.MishkaAuth.Db.Gen.Migration do
  @shortdoc "Generates Guardian.DB's migration"

  @moduledoc """
  Generates the required MishkaAuth's database migration.
  """
  use Mix.Task

  import Mix.Ecto
  import Mix.Generator


  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.migration")

    repos = parse_repo(args)

    Enum.each(repos, fn repo ->

      ensure_repo(repo, args)
      path = Ecto.Migrator.migrations_path(repo)

      :mishka_auth
      |> Application.app_dir()
      |> Path.join("priv/*.eex")
      |> Path.wildcard()
      |> Enum.reverse()
      |> Enum.map(fn file ->
        generated_file(Path.basename(file), file, path)
        :timer.sleep(2000);
      end)

    end)
  end

  def generated_file(filename, source_path, path) do
    generated_file =
      EEx.eval_file(source_path,
        module_prefix: app_module(),
        db_prefix: prefix()
      )

    target_file = Path.join(path, "#{timestamp()}_#{String.trim(filename, ".exs.eex")}.exs")
    create_directory(path)
    create_file(target_file, generated_file)
  end
  def app_module do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()
  end

  def timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end


  def prefix do
    :mishka_auth
    |> Application.fetch_env!(MishkaAuth)
    |> Keyword.get(:prefix, nil)
  end


  def pad(i) when i < 10, do: <<?0, ?0 + i>>
  def pad(i), do: to_string(i)
end
