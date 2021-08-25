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
    |> broadcast_change([:question, :created])
  end

  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
    |> broadcast_change([:question, :updated])
  end

  def delete_question(%Question{} = question) do
    Repo.delete(question)
    |> broadcast_change([:question, :deleted])
  end

  def change_question(%Question{} = question, attrs \\ %{}) do
    Question.changeset(question, attrs)
  end

  defp broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(Questionator.PubSub, @topic, {__MODULE__, event, result})

    {:ok, result}
  end
end
