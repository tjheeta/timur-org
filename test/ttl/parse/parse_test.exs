defmodule Ttl.ParseTest do
  use Ttl.DataCase

  alias Ttl.Parse.Import
  alias Ttl.Parse.Export

  describe "headline" do
    test "import notes" do
      {:ok, doc, objects} = Ttl.Parse.Import.import_file("test/ttl/fixtures/notes.org")
      :ok = Ttl.Parse.Export.export_file("/tmp/notes.org", doc.id, false)
    end
  end
end
