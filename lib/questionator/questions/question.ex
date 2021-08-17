defmodule Questionator.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :text, :string

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text])
    |> validate_required([:text])
    |> unique_constraint(:text)
  end
end
