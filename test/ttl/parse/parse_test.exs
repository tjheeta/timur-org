defmodule Ttl.ParseTest do
  use Ttl.DataCase

  alias Ttl.Parse.Import
  alias Ttl.Parse.Export

  # TODO - tags and multiple scheduled dates are failing
  describe "test complex file" do
    test "import notes" do
      {:ok, doc, objects} = Ttl.Parse.Import.import_file("test/ttl/fixtures/test.org")
      :ok = Ttl.Parse.Export.export_file("/tmp/test.org", doc.id, false)
      {diff, ret} = System.cmd("diff", ["-w" ,"test/ttl/fixtures/test.org", "/tmp/test.org"])
      assert diff == ""
      assert ret == 0
    end
  end
  describe "test README" do
    test "import readme" do
      {:ok, doc, objects} = Ttl.Parse.Import.import_file("README.org")
      :ok = Ttl.Parse.Export.export_file("/tmp/README.org", doc.id, false)
      {diff, ret} = System.cmd("diff", ["-w" ,"README.org", "/tmp/README.org"])
      assert diff == ""
      assert ret == 0
    end
  end
end
