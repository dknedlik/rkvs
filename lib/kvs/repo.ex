defmodule Kvs.Repo do
  use Ecto.Repo,
    otp_app: :kvs,
    adapter: Ecto.Adapters.Postgres
end
