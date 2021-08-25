defmodule Questionator.Questions do
  @moduledoc """
  The Questions context.
  """

  import Ecto.Query, warn: false
  alias Questionator.Questions.Question
  alias Questionator.Repo

  @topic "question"

  def subscribe do
    Phoenix.PubSub.subscribe(Questionator.PubSub, @topic)
  end

  def list_questions, do: Repo.all(Question)

  def get_question!(id), do: Repo.get!(Question, id)

  def create_question(attrs \\ %{}) do
    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
    |> broadcast_change()
  end

  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
    |> broadcast_change()
  end

  def delete_question(%Question{} = question) do
    question
    |> Repo.delete()
    |> broadcast_change()
  end

  def change_question(%Question{} = question, attrs \\ %{}) do
    Question.changeset(question, attrs)
  end

  defp broadcast_change({:ok, result}) do
    Phoenix.PubSub.broadcast(Questionator.PubSub, @topic, "question_changed")

    {:ok, result}
  end
end
