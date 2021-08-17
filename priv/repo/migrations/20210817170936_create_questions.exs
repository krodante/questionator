defmodule Questionator.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :text, :string

      timestamps()
    end

    create unique_index(:questions, [:text])
  end
end
