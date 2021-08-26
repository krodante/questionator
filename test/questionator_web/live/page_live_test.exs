defmodule QuestionatorWeb.PageLiveTest do
  use QuestionatorWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Questions"
    assert render(page_live) =~ "Questions"
  end
end
