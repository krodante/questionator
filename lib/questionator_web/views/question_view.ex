defmodule QuestionatorWeb.QuestionView do
  use QuestionatorWeb, :view

  def question_status(%{asked: true}), do: "asked"
  def question_status(_), do: ""

  def link_text(%{asked: true}), do: "Reset"
  def link_text(_), do: "Ask!"
end
