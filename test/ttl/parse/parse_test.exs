defmodule Ttl.ParseTest do
  use Ttl.DataCase

  alias Ttl.Parse.Import
  alias Ttl.Parse.Export

  # TODO - tags and multiple scheduled dates are failing
  describe "db - test complex file" do
    test "import notes" do
      attrs = %{mode: "default", add_id: false}
      Application.put_env(:ttl, :storage, [backend: :db] )

      {:ok, doc, objects} = Ttl.Parse.Import.import_file(:db, "test/ttl/fixtures/test.org")
      :ok = Ttl.Parse.Export.export_file("/tmp/test-db.org", doc.id, attrs)
      {diff, ret} = System.cmd("diff", ["-w" ,"test/ttl/fixtures/test.org", "/tmp/test-db.org"])
      assert diff == ""
      assert ret == 0
    end
  end
  describe "db - test README" do
    test "import readme" do
      attrs = %{mode: "default", add_id: false}
      Application.put_env(:ttl, :storage, [backend: :db] )

      {:ok, doc, objects} = Ttl.Parse.Import.import_file(:db, "README.org")
      :ok = Ttl.Parse.Export.export_file("/tmp/README-db.org", doc.id, attrs)
      {diff, ret} = System.cmd("diff", ["-w" ,"README.org", "/tmp/README-db.org"])
      assert diff == ""
      assert ret == 0
    end
  end
  describe "kinto - test complex file" do
    test "import notes" do
      attrs = %{mode: "default", add_id: false, kinto_token: "testtoken"}
      Application.put_env(:ttl, :storage, [backend: :kinto] )

      {:ok, doc, objects} = Ttl.Parse.Import.import_file(:kinto, "test/ttl/fixtures/test.org", attrs)
      :ok = Ttl.Parse.Export.export_file("/tmp/test-kinto.org", doc.id, attrs)
      {diff, ret} = System.cmd("diff", ["-w" ,"test/ttl/fixtures/test.org", "/tmp/test-kinto.org"])
      Ttl.Things.kinto_delete_document("testtoken", doc.id)
      assert diff == ""
      assert ret == 0
    end
  end
  describe "kinto - test README" do
    test "import readme" do
      attrs = %{mode: "default", add_id: false, kinto_token: "testtoken"}
      Application.put_env(:ttl, :storage, [backend: :kinto] )

      {:ok, doc, objects} = Ttl.Parse.Import.import_file(:kinto, "README.org", attrs)
      :ok = Ttl.Parse.Export.export_file("/tmp/README-kinto.org", doc.id, attrs)
      {diff, ret} = System.cmd("diff", ["-w" ,"README.org", "/tmp/README-kinto.org"])
      Ttl.Things.kinto_delete_document("testtoken", doc.id)
      assert diff == ""
      assert ret == 0
    end
  end
  # TODO - import a file to db, generate the file, regenerate it
  # Ensure no changes to the db
end
