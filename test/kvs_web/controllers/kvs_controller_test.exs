defmodule KvsWeb.KvsControllerTest do
  use KvsWeb.ConnCase, async: true
  @insert_object_attr %{value: %{val1: "val1", val2: 1}}
  @ttl_object_attr %{value: %{val1: "val1", val2: 1}, ttl: 1}

  describe "collections ->" do
    test "create a new collection", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"

      # clean up
      delete(conn, "/api/collection/test")
    end

    test "fail create if already exists", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"
      conn = put(conn, "/api/collection/test")
      assert json_response(conn, 400) == %{"error" => "collection exists"}
      # clean up
      delete(conn, "/api/collection/test")
    end

    test "insert key in collection", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"
      conn = put(conn, "/api/collection/test/key/key1", @insert_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "collection" => "test",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      # clean up
      delete(conn, "/api/collection/test")
    end

    test "get key from collection", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"
      conn = put(conn, "/api/collection/test/key/key1", @insert_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "collection" => "test",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      conn = get(conn, "/api/collection/test/key/key1", @insert_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "collection" => "test",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      # clean up
      delete(conn, "/api/collection/test")
    end

    test "missing key from existing collection", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"
      conn = get(conn, "/api/collection/test/key/key1")

      assert text_response(conn, 404) == ""
      # clean up
      delete(conn, "/api/collection/test")
    end

    test "key from missing collection", %{conn: conn} do
      conn = get(conn, "/api/collection/test/key/key1")

      assert text_response(conn, 404) == ""
    end

    test "delete collection", %{conn: conn} do
      conn = put(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ "ok"
      conn = put(conn, "/api/collection/test/key/key1", @insert_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "collection" => "test",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      conn = get(conn, "/api/collection/test/key/key1")

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "collection" => "test",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      conn = delete(conn, "/api/collection/test")
      assert text_response(conn, 200) =~ ""

      conn = get(conn, "/api/collection/test/key/key1")
      assert text_response(conn, 404) =~ ""
    end
  end

  describe "keys ->" do
    test "insert key", %{conn: conn} do
      conn = put(conn, "/api/key/key1", @insert_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "value" => %{"val1" => "val1", "val2" => 1}
             }
    end

    test "get key", %{conn: conn} do
      conn = put(conn, "/api/key/key1", @insert_object_attr)
      assert json_response(conn, 200)
      conn = get(conn, "/api/key/key1")

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "value" => %{"val1" => "val1", "val2" => 1}
             }
    end

    test "missing key", %{conn: conn} do
      conn = get(conn, "/api/key/does_not_exist")
      assert text_response(conn, 404) =~ ""
    end

    test "delete key", %{conn: conn} do
      conn = put(conn, "/api/key/key1", @insert_object_attr)
      assert json_response(conn, 200)
      conn = get(conn, "/api/key/key1")

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      conn = delete(conn, "/api/key/key1")
      assert text_response(conn, 200) =~ ""
      conn = get(conn, "/api/key/key1")
      assert text_response(conn, 404) =~ ""
    end
  end

  describe "ttl" do
    test "expire key", %{conn: conn} do
      conn = put(conn, "/api/key/key1", @ttl_object_attr)

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      conn = get(conn, "/api/key/key1")

      assert json_response(conn, 200) == %{
               "key" => "key1",
               "value" => %{"val1" => "val1", "val2" => 1}
             }

      :timer.sleep(2000)
      conn = get(conn, "/api/key/key1")
      assert text_response(conn, 404) =~ ""
    end
  end
end
