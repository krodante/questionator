# Connecting a Remote Team with Phoenix LiveView

## Intro

Even before Covid-Times, TRR's engineers worked together remotely all over the world. I was once on a team where the Project Manager (PM) and I were the only members who worked out of HQ. We had to learn how to connect with each other in ways that didn't involve being in the same office together.

One method that really worked for us was our "Weekly Question Day". Our PM found a list of classic icebreaker questions and would ask us one during standup each week. It added on maybe an extra 10 minutes to standup, but it was so worth the chance to get to know my teammates better. We'd learn about each other's crazy hobbies, or funniest childhood memories, or hypothetical zombie apocalypse preparedness - it really helped us connect and feel more empathy towards each other.

Unfortunately, keeping up with all those questions is a lot of work. You'd forget which ones you've already asked or which Google doc the list was in, so the management of this super fun activity could become really tiresome really fast.

Because I love my teammates, I decided to come up with a little app to keep track of our questions - and get some LiveView practice in while I'm at it!

## Step 0: Environment Setup

This guide assumes that your environment will be set up with these tools and versions:

* [Elixir](https://elixir-lang.org/install.html#distributions) 1.11.3
* [Erlang](https://elixir-lang.org/install.html#installing-erlang) 23.1.4
* [PostgreSQL](https://www.postgresql.org/download/) 13.2
* [hex](https://hex.pm/docs/usage) 0.21.2
* [phx_new](https://hexdocs.pm/phoenix/installation.html#phoenix) (Phoenix) 1.5.10

If your environment is already set up, feel free to skip to [Step 1](#Step-1-Using-Generatorss-to-Create-the-App)! If not, keep on reading!

You can confirm your Elixir, Erlang, and Hex versions all at once with `mix hex.info`, PostgreSQL  with `postgres -V`, and Phoenix with `mix archive`:

```bash
$ mix hex.info
Hex:    0.21.2
Elixir: 1.11.3
OTP:    23.1.4

Built with: Elixir 1.11.4 and OTP 21.3

$ postgres -V
postgres (PostgreSQL) 13.2

$ mix archive
* hex-0.21.2
* phx_new-1.5.10
```

## Step 1: Using Generators to Create the App

Now we can generate a new app! Phoenix comes packed with various [mix tasks](https://hexdocs.pm/phoenix/mix_tasks.html#content) that allow us to quickly create the foundation for an application. The most basic generator is `mix phx.new my_app`, which will set up the bare structure, and then you can call other generators to add on it - if you want. You could also write your modules from scratch, but it's recommended to use community best practices with regards to application structure.

According to the [LiveView installation documentation](https://hexdocs.pm/phoenix_live_view/installation.html), all we need to do is enter `mix phx.new my_app --live` in the terminal. This is the same as the as the call for a regular Phoenix app, but the `--live` tag indicates that the generator will create additional folders and files for our LiveView modules.

```
$ mix phx.new questionator --live
# ... installing lots of boilerplate ...
```

The generator not only creates the necessary folders and files, but also gives us instructions on how to get our app up and running.

I ran into errors with the versions of node and npm on my machine, so I skipped the `cd assets ...` step. You don't _need_ node for this project, so you're welcome to move onto the database step. But if you do change into the assets directory, remember to go back to the project root directory `/questionator` before running `mix ecto.migrate`.

Since we're using PostgreSQL for our database, we can skip the `configure your database in config/dev.exs` step. However, if you're using Docker, you will need to update your application like so:

Change the `hostname` in `config/dev.exs`:

```elixir
# config/dev.exs

use Mix.Config

# Configure your database
config :questionator, Questionator.Repo,
  username: "postgres",
  password: "postgres",
  database: "questionator_dev",
  hostname: "db",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# ... more config
```

Update your `docker-compose.yml`:

```yaml=
version: '3.1'

services:
  app:
    build:
      context: .
    depends_on:
      - db
    ports:
      - 4000:4000
    restart: always
    volumes:
      - .:/app

  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: postgres
    restart: always
```

And use this as your `Dockerfile`:

```
FROM elixir:latest

WORKDIR /app

COPY . /app

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix do compile

CMD mix phx.server
```

Once your database in configured, we use another mix task to create it:

```
$ mix ecto.create
```

Let's get this server running with `mix phx.server` and navigate to `http://localhost:4000` to bask in the glow of a new Phoenix app!

![](https://i.imgur.com/5HUPaKx.png)

Ahhh the Phoenix Framework main page. But if you check out the [LiveDashboard](http://localhost:4000/dashboard/home) link in the top-right corner, you see this beauty:

![](https://i.imgur.com/53oZ4hN.png)

All the metrics!! Super fast page views! Dynamic rendering of data! And backend developers rejoice because there is NO JAVASCRIPT!

I love this [dashboard](https://github.com/phoenixframework/phoenix_live_dashboard) because it gives you a quick preview of all the goodness LiveView has to offer, along with great insight into how your application is running. LiveDashboard provides real-time performance monitoring and debugging tools, and you can use the [PageBuilder](https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.PageBuilder.html#content) module to customize your dashboard.

In order to manage what questions we want to ask, we'll need to be able to add some! We'll use another mix task to generate a [context](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html). Using the context generator will create all the basic functions (create, read, update, edit) we will need to interact with the [Ecto schema](https://hexdocs.pm/ecto/Ecto.Schema.html).

The `mix phx.gen.context` task takes several arguments. The first argument is the context module, then the schema module, and then its plural name (which is just the table name). We want to create a `questions` table with two columns: `text` as a unique String type, and `asked` as a Boolean type, so our task will look like this:

```
$ mix phx.gen.context Questions Question questions text:unique asked:boolean
* creating lib/questionator/questions/question.ex
* creating priv/repo/migrations/20210817170936_create_questions.exs
* creating lib/questionator/questions.ex
* injecting lib/questionator/questions.ex
* creating test/questionator/questions_test.exs
* injecting test/questionator/questions_test.exs
```

For fun, let's check out what this generator is creating:

* `lib/questionator/questions/question.ex` is our schema file. This file is used to map any data source to an Elixir struct - in our case, data in the `questions` table can represented as `%Question{}` in our application
* `priv/repo/migrations/20210817170936_create_questions.exs` is our migration file, where we define changes that we want to make to the database. We'll be creating a new table and adding `text` and `asked` columns.
* `lib/questionator/questions.ex` contains the functions we'll use to manipulate data in the `questions` table, specifically: `list_questions/0`, `get_question!/1`, `create_question/1`, `update_question/2`, `delete_question/1`
* `test/questionator/questions_test.exs` is a test file for the `Questions` module because yay testing!

Since we have a new handy dandy migration file, we'll use another mix task to create our `questions` table:

```bash
$ mix ecto.migrate

13:38:32.649 [info]  == Running 20210816201126 Questionator.Repo.Migrations.AddQuestionsTable.change/0 forward

13:38:32.659 [info]  create table questions

13:38:32.694 [info]  == Migrated 20210816201126 in 0.0s
```



## Step 2: Adding Questions

All right! Now we have a place to store the data, so let's create a form to add some!

We'll need to add resources for `Question` in our [router](https://hexdocs.pm/phoenix/Phoenix.Router.html). Normally, we'd call `resources "/questions", QuestionController` in order to connect HTTP actions and our application, but LiveView functions a bit differently. In our case, we'll call `live "/", QuestionLive, :index`. This will route any requests to `"/"` to our (soon to be created) `QuestionLive` module.

Let's replace the call to the `PageLive` module to `QuestionLive` instead.

```elixir
# lib/questionator_web/router.ex

# ...
# live "/", PageLive, :index <--- replace this with the following
live "/", QuestionLive, :index # <--- we want this
# ...
```

When we reload the page we'll get this useful error message:

![](https://i.imgur.com/1NaykHp.png)

So let's create `QuestionLive`!

Since we're replacing the `PageLive` module, let's take some basic functions from there and create a `QuestionLive` module at `lib/questionator_web/live/question_live.ex` to render a list of questions:

```elixir
# lib/questionator_web/live/question_live.ex

defmodule QuestionatorWeb.QuestionLive do
  use QuestionatorWeb, :live_view

  alias Questionator.Questions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, questions: Questions.list_questions())}
  end
end
```

Ok, so what's happening? The [LiveView.mount](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:mount/3) callback is called when the router receives a request to the `live "/", QuestionLive, :index` route. `mount` performs the initial page load and opens the socket that will pass interactions between the client and backend. In this case, we want to load our list of questions from the database and return that to the client.

![](https://i.imgur.com/GEULHPc.png)

Indeed, we do not have a `render/1` function! Let's add the `question_live.html.leex` file, but we'll add it to the `/templates` folder instead of `/live`. If we're using best practices (and we are because we're awesome), Phoenix organizes its rendering files in the `/templates` folder, and functions that facilitate rendering are placed in a view module in the `/views` folder.

We'll create the view module first so that we can connect the `QuestionLive` module to the template. Create a file called `question_view.ex` in `lib/questionator_web/views`:

```elixir
# lib/questionator_web/views/question_view.ex

defmodule QuestionatorWeb.QuestionView do
  use QuestionatorWeb, :view
end
```

Whenever we want to add fancy helper functions for our template, we'll put them in this file.

Next we'll create our template! We'll add a `/question` folder in `/templates` to separate Question-related templates from our root templates.


For now we can just add some basic HTML to our new template:

```elixir
# lib/questionator_web/templates/question/question_live.html.leex

<h1>Questions</h1>

<table>
  <thead>
    <tr>
      <th>Question</th>
      <th>Asked</th>
    </tr>
  </thead>
  <tbody>
    <%= for question <- @questions do %>
      <tr>
        <td><%= question.text %></td>
        <td><%= question.asked %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

While we're at it, go to the `root.html.leex` template and remove the Phoenix header. The `<body>` section should just have the [`@inner_content`](https://hexdocs.pm/phoenix/views.html#layouts) call:

```elixir
# lib/questionator_web/templates/layout/root.html.leex

# ...
<body>
  <%= @inner_content %>
</body>
# ...
```

Now `http://localhost:4000/` will have a basic table!

![](https://i.imgur.com/CprvmQZ.png)

But empty tables are sad tables, so let's get some data in there.

Add a form at the top of the `question_live` template:

```elixir
# lib/questionator_web/templates/question/question_live.html.leex

<h1>Questions</h1>

<form action="#" phx-submit="create">
  <%= text_input :question, :text, placeholder: "Add a question" %>
  <%= submit "Add Question", phx_disable_with: "Adding..." %>
</form>

# ...

```

![](https://i.imgur.com/hQkywaK.png)

Nothing fancy, just a little text form. The key part here, though, is the `phx-submit="create"` attribute on `form`. When you submit the form, it will trigger the `phx-submit` [form binding](https://hexdocs.pm/phoenix_live_view/form-bindings.html), which will send a "create" event to our `QuestionLive` module.

When you try to add a question in the form, it looks like everything is loading, but we don't see our new question. If you hop over to the server, you'll see an error output:

```
** (UndefinedFunctionError) function QuestionatorWeb.QuestionLive.handle_event/3 is undefined or private
    # QuestionatorWeb.QuestionLive.handle_event("create", %{"question" => %{"text" => "What's your favorite color?"}}, #Phoenix.LiveView.Socket<assigns: %{flash: %{}, live_action: :index, questions: []}, changed: %{}, endpoint: QuestionatorWeb.Endpoint, id: "phx-FpwqTlnMqzCI7QIG", parent_pid: nil, root_pid: #PID<0.925.0>, router: QuestionatorWeb.Router, transport_pid: #PID<0.921.0>, view: QuestionatorWeb.QuestionLive, ...>)
```

Totally expected, since we haven't coded the `handle_event` function yet! Let's add that to `QuestionLive`:

```elixir
# lib/questionator_web/live/question_live.ex

@impl true
def handle_event("create", %{"question" => question}, socket) do
  Questions.create_question(question)

  {:noreply, assign(socket, questions: Questions.list_questions())}
end
```

Since we're also adding the `questions` assign in `mount`, we can refactor this code a bit by adding a common `fetch` function, so that the whole file looks like this:

```elixir
# lib/questionator_web/live/question_live.ex

defmodule QuestionatorWeb.QuestionLive do
  use QuestionatorWeb, :live_view

  alias Questionator.Questions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, fetch(socket)}
  end

  @impl true
  def handle_event("create", %{"question" => question}, socket) do
    Questions.create_question(question)

    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    assign(socket, questions: Questions.list_questions())
  end
end
```

Now we can successfully add a new question on the same page!

![](https://i.imgur.com/hz71N8A.png)


------------> new question (1) ss (but make it a gif) <---------------

For this tutorial, I actually want to add a bunch of questions at once, so let's add another form to the `question_live.html.leex` template with a different `phx-submit` attribute:

```html
# lib/questionator_web/templates/question/question_live.html.leex

<form action="#" phx-submit="create_multiple">
  <%= textarea :question, :text, placeholder: "Add multiple questions,\none per line" %>
  <%= submit "Add Questions", phx_disable_with: "Adding..." %>
</form>
```

And we'll add another `handle_event` function to the `question_live.ex` module to capture the `create_multiple` action:

```elixir
# lib/questionator_web/live/question_live.ex

@impl true
def handle_event("create_multiple", %{"question" => params}, socket) do
  create_multiple_questions(params)

  {:noreply, fetch(socket)}
end

defp create_multiple_questions(%{"text" => questions}) do
  questions
  |> String.split(~r/\R/)`
  |> Enum.map(&(%{"text" => &1}))
  |> Enum.each(&(Questions.create_question(&1)))
end
```

We can kindly ask our users to submit multiple questions separated by a new line, and hopefully it will parse correctly :smile: For example, using this input:

```
What is your pet's name?
What was the first concert you went to?
Do you have any siblings?
```

Should give us all these new questions!

![](https://i.imgur.com/Sr7krb3.png)


------------> new questions ss but a gif instead <---------------

All right! So! We can add questions individually or in bulk, so at least our question manager person can keep track of them. Now we need to help them check/uncheck questions off the list.

## Step 3: Using PubSub to Manage Questions

Let's say that our team decides to not have a single question manager person, but that they all want to contribute to the list, potentially at the same time. Maybe you'd say, "just use a spreadsheet!", but at some point or another we've had to deal with multiple people adding data to a sheet simultaneously - it's just messy. Wouldn't it be great if multiple users could be using the same web app, make changes, and then see the changes that others are making in real time? Enter: PubSub.

When the community gets hyped about the glory of LiveView, it's more likely that they're talking about [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html). PubSub allows our LiveView component to listen to changes in the database and update the component even if it is in a different process. For example, if we open up another localhost tab and add a question, that question will not be automatically added to our first tab:

-----------> 2 tab screenshot - but a gif instead <---------------

This is definitely a problem if you have multiple clients working on the same app and you want them to have real-time information about changes.

Thankfully, Phoenix already comes with PubSub, so we just need to add it to our `Questionator.Questions` module.

```elixir
# lib/questionator/questions.ex

@topic inspect(__MODULE__)

def subscribe do
  Phoenix.PubSub.subscribe(Questionator.PubSub, @topic)
end
```

This function allows `QuestionLive` to listen for any changes that happen in the database. We'll use the `subscribe` function in `mount` to listen for changes on the questions table

```elixir
# lib/questionator_web/live/question_live.ex

def mount(_params, _session, socket) do
  Questions.subscribe()

  {:ok, fetch(socket)}
end
```

Similar to the `handle_event` function, we'll need to add a `handle_info` function that will be called whenever a new message is published to the topic we are listening to:

```elixir
# lib/questionator_web/live/question_live.ex

def handle_info({Questions, [:question | _], _}, socket) do
  {:noreply, fetch(socket)}
end
```

The `handle_info` function pattern matches on the topic - `Questions` in our case - and any changes that have occured in the `:question`. We return the current list of questions from the database (remember: `fetch/1` assigns `Questions.list_questions()` to the socket) within the same process as the LiveView component.

We have our listener, so now we need to broadcast the events. Back in `Questionator.Questions`, we'll add a `broadcast_change` function and add it to our database API functions so that the LiveView component will change when the database does.

```elixir
# lib/questionator/questions.ex

# ...
def create_question(attrs \\ %{}) do
  %Question{}
  |> Question.changeset(attrs)
  |> Repo.insert()
  |> broadcast_change([:question, :updated])
end

def update_question(%Question{} = question, attrs) do
  question
  |> Question.changeset(attrs)
  |> Repo.update()
  |> broadcast_change([:question, :updated])
end

def delete_question(%Question{} = question) do
  Repo.delete(question)
  |> broadcast_change([:question, :updated])
end

# ...

defp broadcast_change({:ok, result}, event) do
  Phoenix.PubSub.broadcast(Questionator.PubSub, @topic, {__MODULE__, event, result})

  {:ok, result}
end
```

Restart your server and open your application in two windows. Add a question and watch both windows change in real time! :sparkles: Now we can all help come up with questions for our super fun weekly question day!

Our app is now wired to update our questions in real time too, so let's work on marking questions off the list. We want to know if we've already asked a question, but we don't necessarily want to delete that question from the list, so we'll add a way to toggle if the questions have been asked or not.

Back in our `question_live.html.leex` template, change the `<td><%= question.asked %></td>` field to a link that we'll use to update the question:

```html
# lib/questionator_web/templates/question/question_live.html.leex

# ...
<tbody>
  <%= for question <- @questions do %>
    <tr class="<%= question_status(question) %>">
      <td><%= question.text %></td>
      <td>
        <%= link(link_text(question), to: "#", phx_click: "toggle_asked", phx_value_id: question.id, value: question.asked) %>
      </td>
    </tr>
  <% end %>
</tbody>
# ...
```

This `link` function is neat because it adds the `phx_click` and `phx_value_id` attributes. These are like the `phx-submit` form binding. When you click on this element it will trigger the `handle_event` callback and match on "toggle_asked", so let's add that now:

```elixir
# lib/questionator_web/live/question_live.ex

# ...
@impl true
def handle_event("toggle_asked", %{"id" => id}, socket) do
  Questions.get_question!(id)
  |> toggle_question()

  {:noreply, assign(socket, questions: Questions.list_questions())}
end

defp toggle_question(question) do
  attrs = case question.asked do
    true -> %{"asked" => false}
    false -> %{"asked" => true}
  end

  Questions.update_question(question, attrs)
end
# ...
```

The backend is hooked up, but we won't be able to notice any changes, so let's add a class to our rows to indicate whether or not the question has been asked. Add a helper function in `QuestionLive` to supply the appropriate class:

```elixir
# lib/questionator_web/live/question_live.ex

# ...
def question_status(%{asked: true}), do: "asked"
def question_status(_), do: ""

def question_status(%{asked: true}), do: "asked"
def question_status(_), do: ""
# ...
```

Then add the `.asked` class to our CSS so we can definitely see which questions we've asked already. Create a `question.css` file in `assets/css` and add this little bit of CSS (or however you'd like to style it):

```css
.asked {
  color: grey;
  text-decoration: line-through;
}
```

And don't forget to add your new stylesheet to `app.css` (note: you could also just add that `.asked` class to `app.css` instead of creating a new `question.css` file, but I personally like keeping separate functionality in its own namespace):

```css
@import "./phoenix.css";
@import "./question.css";
# ...
```

Now if you go back to your app and click "Ask!", you'll see that the question has been sent to the bottom of the list and has your fancy `.asked` class!

## Conclusion

