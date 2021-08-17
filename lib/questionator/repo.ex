defmodule Questionator.Repo do
  use Ecto.Repo,
    otp_app: :questionator,
    adapter: Ecto.Adapters.Postgres
end
