defmodule Questionator.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :text, :string
    field :asked, :boolean

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :asked])
    |> validate_required([:text])
    |> unique_constraint(:text)
  end
end
