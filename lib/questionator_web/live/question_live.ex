defmodule QuestionatorWeb.QuestionLive do
  use QuestionatorWeb, :live_view

  alias Questionator.Questions
  alias QuestionatorWeb.QuestionView

  @impl true
  def mount(_params, _session, socket) do
    Questions.subscribe()

    {:ok, fetch(socket)}
  end

  @impl true
  def render(assigns), do: QuestionView.render("question_live.html", assigns)

  @impl true
  def handle_event("create", %{"question" => params}, socket) do
    Questions.create_question(params)

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_event("create_multiple", %{"question" => params}, socket) do
    create_multiple_questions(params)

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_event("toggle_asked", %{"id" => id}, socket) do
    id
    |> Questions.get_question!()
    |> toggle_question()

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_info("question_changed", socket) do
    {:noreply, fetch(socket)}
  end

  defp create_multiple_questions(%{"text" => questions}) do
    questions
    |> String.split(~r/\R/)
    |> Enum.map(&%{"text" => &1})
    |> Enum.each(&Questions.create_question(&1))
  end

  defp fetch(socket) do
    assign(socket, questions: Questions.list_questions())
  end

  defp toggle_question(question) do
    attrs =
      case question.asked do
        true -> %{"asked" => false}
        false -> %{"asked" => true}
      end

    Questions.update_question(question, attrs)
  end
end
