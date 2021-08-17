defmodule QuestionatorWeb.QuestionLive do
  use QuestionatorWeb, :live_view

  alias Questionator.Questions

  @impl true
  def mount(_params, _session, socket) do
    Questions.subscribe()

    {:ok, fetch(socket)}
  end

  @impl true
  def handle_event("create", %{"question" => params}, socket) do
    Questions.create_question(params)

    {:noreply, assign(socket, questions: Questions.list_questions())}
  end

  @impl true
  def handle_event("create_multiple", %{"question" => params}, socket) do
    create_multiple_questions(params)

    {:noreply, assign(socket, questions: Questions.list_questions())}
  end

  @impl true
  def handle_event("toggle_asked", %{"id" => id}, socket) do
    Questions.get_question!(id)
    |> toggle_question()

    {:noreply, assign(socket, questions: Questions.list_questions())}
  end

  @impl true
  def handle_info({Questions, [:question | _], _}, socket) do
    {:noreply, fetch(socket)}
  end

  defp create_multiple_questions(%{"text" => questions}) do
    questions
    |> String.split("\r\n")
    |> Enum.map(&(%{"text" => &1}))
    |> Enum.each(&(Questions.create_question(&1)))
  end

  def question_status(%{asked: true}), do: "asked"
  def question_status(_), do: ""

  def link_text(%{asked: true}), do: "Reset"
  def link_text(_), do: "Ask!"

  defp fetch(socket) do
    assign(socket, questions: Questions.list_questions())
  end

  defp toggle_question(question) do
    attrs = case question.asked do
      true -> %{"asked" => false}
      false -> %{"asked" => true}
    end

    Questions.update_question(question, attrs)
  end
end
