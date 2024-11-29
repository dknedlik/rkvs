defmodule KvsWeb.KvsController do
  require Logger
  use Phoenix.Controller, formats: [:json]

  def put_key(conn, %{"key" => key, "value" => value} = params) do
    ttl = Map.get(params, "ttl", 0)
    put_key_to_table(:kvs, key, value, ttl)

    conn
    |> json(%{key: key, value: value})
  end

  def get_key(conn, %{"key" => key}) do
    case get_key_from_table(:kvs, key) do
      {:ok, value} ->
        conn
        |> json(%{key: key, value: value})

      _ ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "")
    end
  end

  def delete_key(conn, %{"key" => key}) do
    delete_key_from_table(:kvs, key)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "")
  end

  def put_collection(conn, %{"collection" => collection}) do
    try do
      Kvs.Application.create_ets(String.to_atom(collection))

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "ok")
    rescue
      _ in ArgumentError ->
        conn
        |> put_status(400)
        |> json(%{error: "collection exists"})
    end
  end

  def delete_collection(conn, %{"collection" => collection}) do
    try do
      table = String.to_existing_atom(collection)
      delete_table(table)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "")
    rescue
      _ in ArgumentError ->
        conn
        |> put_resp_content_type("text/json")
        |> send_resp(404, "")
    end
  end

  def get_key_from_collection(conn, %{"key" => key, "collection" => collection}) do
    try do
      table = String.to_existing_atom(collection)

      case get_key_from_table(table, key) do
        {:ok, value} ->
          conn
          |> json(%{collection: collection, key: key, value: value})

        _ ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(404, "")
      end
    rescue
      _ in ArgumentError ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "")
    end
  end

  def put_key_to_collection(
        conn,
        %{"key" => key, "collection" => collection, "value" => value} = params
      ) do
    try do
      table = String.to_existing_atom(collection)
      ttl = Map.get(params, "ttl", 0)
      put_key_to_table(table, key, value, ttl)

      conn
      |> json(%{collection: collection, key: key, value: value})
    rescue
      _ in ArgumentError ->
        conn
        |> put_resp_content_type("text/json")
        |> send_resp(404, "")
    end
  end

  def delete_key_from_collection(conn, %{"key" => key, "collection" => collection}) do
    try do
      table = String.to_existing_atom(collection)
      delete_key_from_table(table, key)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "")
    rescue
      _ in ArgumentError ->
        conn
        |> put_resp_content_type("text/json")
        |> send_resp(404, "")
    end
  end

  @spec put_key_to_table(table, key, value, ttl) :: boolean()
        when table: atom(), key: term(), value: term(), ttl: integer()
  defp put_key_to_table(table, key, value, ttl) when is_atom(table) and is_integer(ttl) do
    case ttl do
      n when n > 0 ->
        expires = :erlang.system_time(:seconds) + ttl
        :ets.insert(table, {key, {value, expires}})

      _ ->
        :ets.insert(table, {key, value})
    end
  end

  @spec get_key_from_table(table, key) :: tuple() when table: atom(), key: term()
  defp get_key_from_table(table, key) when is_atom(table) do
    case :ets.lookup(table, key) do
      [{_, {value, expires}} | _] ->
        case :erlang.system_time(:second) do
          n when n > expires ->
            Logger.info("found a expired entry")
            {:err, "expired"}

          _ ->
            {:ok, value}
        end

      [{_, value} | _] ->
        {:ok, value}

      [] ->
        {:err, "not found"}
    end
  end

  @spec delete_table(table) :: true when table: atom()
  defp delete_table(table) when is_atom(table) do
    :ets.delete(table)
  end

  @spec delete_key_from_table(table, key) :: true when table: atom(), key: term()
  defp delete_key_from_table(table, key) when is_atom(table) do
    :ets.delete(table, key)
  end
end
