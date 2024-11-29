defmodule Kvs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KvsWeb.Telemetry,
      Kvs.Repo,
      {DNSCluster, query: Application.get_env(:kvs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kvs.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Kvs.Finch},
      # Start a worker by calling: Kvs.Worker.start_link(arg)
      # {Kvs.Worker, arg},
      # Start to serve requests, typically the last entry
      KvsWeb.Endpoint
    ]

    create_ets(:kvs)
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kvs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KvsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @spec create_ets(atom()) :: atom()
  def create_ets(name) when is_atom(name) do
    :ets.new(name, [
      # gives us key=>value semantics
      :set,

      # allows any process to read/write to our table
      :public,

      # allow the ETS table to access by it's name,
      :named_table,

      # favor read-locks over write-locks
      read_concurrency: true,

      # internally split the ETS table into buckets to reduce
      # write-lock contention
      write_concurrency: true
    ])
  end
end
