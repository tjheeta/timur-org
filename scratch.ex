
"""
d = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
IO.inspect d.objects
# create a document
{:ok, doc_id} = Map.from_struct(d) |> Map.take([:name]) |> Ttl.Things.create_document()
doc_id.id

Enum.reduce(d.objects, 0, fn(n, acc) ->
  IO.inspect acc
  IO.inspect n
  acc + 1
end)

Ecto.UUID.bingenerate()

# may have uuids or not on each object
# need to get the document uuid - use case/with
# a) either need to insert each object, get all the uuids
# b) generate all the uuids for each object and put them in an array
# then finally update the document with the ordered list of uuid's

Ttl.Things.list_objects
Ttl.Things.list_documents
obj = Enum.at(d.objects, 1)
{:ok, tmp} = Map.from_struct(obj) |> Map.put_new(:document_id, doc_id.id) |> Ttl.Things.create_object()

o1 = Map.from_struct(obj) |> Map.put_new(:document_id, doc_id.id) |> Map.put_new(:id, Ecto.UUID.bingenerate())
Ttl.Things.create_object(o1)
IO.inspect tmp.id

# this is working with on_conflict and changeset
# eventually, need to have version control on objects
# so just select them all and use insert_or_update_all
{:ok, obj_id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
o1 = Map.from_struct(obj) |> Map.put_new(:document_id, doc_id.id) |> Map.put_new(:id, obj_id)
o1 = Map.update(o1, :version, 1, &(&1 + 1))
Ttl.Things.create_or_update_object(o1)

"""

"""
d = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
x = Ttl.Parse.build_ast(d, [])
Enum.at(x, 790)  # this is the logbook
Enum.at(x, 794) 
Enum.at(x, 796) 
IO.inspect(x, limit: :infinity)
Enum.at(d, 1620)
Enum.at(d, 1621)
Enum.at(d, 1618)
Enum.at(d, 1619)
line = Enum.at(d, 1618).line
line
res = Regex.named_captures(~r/^(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<priority>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, line) 
Ttl.Parse.Object
doc = %Ttl.Parse.Document{}
IO.inspect doc
IO.inspect doc.objects
doc
d2 = %{doc | objects: [1, 2,3 ]}
d2 = %{doc | objects: [5 | d2.objects]}
IO.inspect d2
# slurp_until(t, func_end, func_acc, skip_end_line, %{acc | content: tmp}, ast)
Enum.reduce(x, doc, fn(n, acc)  ->
  cond do
    n.__struct__ == Ttl.Parse.Heading ->
      IO.inspect "HERE"
      Enum.reduce_while
    true -> IO.inspect "THERE"
  end
  IO.inspect n.lnb
end)

Enum.reduce(x, doc, fn(n, acc)  ->
IO.inspect n.lnb
end)

d = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
d = Ttl.Parse.parse("/tmp/a1.org")
x = Ttl.Parse.build_ast(d, [])
Enum.at(d, 60)
Enum.at(x,2)
Enum.at(x, 3)
Enum.at(x, 4)
Enum.at(x, 5)

d = Ttl.Parse.parse("/tmp/a2.org")
x = Ttl.Parse.build_ast(d, [])

doc = Ttl.Parse.create_document(x)
IO.inspect doc
IO.inspect doc.objects
obj = Enum.at(doc.objects, 312)
IO.inspect obj
IO.puts (obj.content )
obj = %{obj | closed: 1, scheduled: 2}
tmp = List.replace_at(doc.objects, 10, obj)
Enum.at(tmp, 10)
hd(doc.objects)
List.last(doc.objects)

#iex:break()
exit
line2 = "CLOSED: [2016-06-01 Wed 00:31] SCHEDULED: <2016-05-31 Tue>"
line1 = "SCHEDULED: <2016-05-31 Tue>"
line3 = "CLOSED: [2016-06-01 Wed 00:31] SCHEDULED: <2016-05-31 Tue> DEADLINE: <2016-06-01 Wed>"

Regex.named_captures(~r/(?<keyword>(DEADLINE|SCHEDULED|CLOSED)):/, line3) 
Regex.named_captures(~r/(?<k1>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v1>.+)\s*(?<k2>(DEADLINE|SCHEDULED|CLOSED))    /, line3) 
Regex.named_captures(~r/(?<k1>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v1>.+)\s*(?<k2>(DEADLINE|SCHEDULED|CLOSED))/, line3) 
# with options
Regex.named_captures(~r/((?<k1>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v1>.+))?\s+((?<k2>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v2>.+)\s*)?((?<k3>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v3>.+)\s*)?/ , line3)
Regex.named_captures(~r/((?<k1>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v1>.+)\s*)?((?<k2>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v2>.+)\s*)((?<k3>(DEADLINE|SCHEDULED|CLOSED)):\s*(?<v3>.+)\s*)/ , line2)
Regex.named_captures(~r/(DEADLINE:\s*(?<v1>.+))/, line3) 
Regex.named_captures(~r/(SCHEDULED:\s*(?<v1>[^>]+))/, line3) 
Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<v1>[^>\]]+)([\]>]))/, line1) 
Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<v1>[^>\]]+)([\]>]))/, line3) 

m1 = Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<closed>[^>\]]+)([\]>]))/, line1) || %{}
m1 = %{}
m1 = (Regex.named_captures(~r/(DEADLINE:\s*([\[<])(?<deadline>[^>\]]+)([\]>]))/, line1) || %{}) |> Map.merge(m1)
m1 = Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled>[^>\]]+)([\]>]))/, line1) |> Map.merge(m1)
%Planning{line: line, lnb: lnb}
Map.merge()

r = (Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<closed>[^>\]]+)([\]>]))/, line3) || %{} )
r = (Regex.named_captures(~r/(DEADLINE:\s*([\[<])(?<deadline>[^>\]]+)([\]>]))/, line3) || %{}) |> Map.merge(r)
r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled>[^>\]]+)([\]>]))/, line3) || %{}) |> Map.merge(r)
Map.get(r, "scheduled1")
"""
