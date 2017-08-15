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

len = length(d.objects)
Enum.map([0..len-1], &(Ecto.UUID.bingenerate()))
bin_ids = for n <- 0..len-1, do: Ecto.UUID.bingenerate()

Enum.zip(0..len-1, bin_ids )
Enum.map(d.objects, fn(x) -> %{x | id: Ecto.UUID.bingenerate()} end)




Enum.filter(d.objects, fn(x) -> x.__struct__ == Ttl.Parse.Object end) |>length

#Enum.filter(d.objects, fn(x) -> x.__struct__ == Ttl.Parse.Object end) |> Enum.map( fn(x) -> %{x | id: Ecto.UUID.bingenerate()} end)

Enum.
Enum.at(d.objects, 0)

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


d = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
# what is my document_id?

{:ok, doc_id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
d = Map.put_new(d, :id, doc_id)
# this creates an id if it doesn't already exist
# this date parsing is completely broken. Do it in the damn parser
current_objects = Enum.map(d.objects, fn(x) ->
  f_generate_id = fn ->
    {:ok, id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
    id
  end
  f_generate_version = fn -> 1 end
  f_parse_date = fn(x) -> end
  t1 = Map.from_struct(x) |> Map.put_new_lazy(:id, f_generate_id) |> Map.put_new_lazy(:version, f_generate_version ) |> Map.put_new(:document_id, doc_id)
end)
#  new_dates = Map.take(t1, [:deadline, :scheduled, :closed])  |> Enum.map(fn({k,v}) ->
#    IO.inspect v
#    case v do
#      nil -> {k,v}
#      v ->
#        {:ok, date} = cond do
#          String.length(v) > 22 -> {:ok, v}
#            #IO.inspect v
#            #Timex.parse(v, "%Y-%m-%d %a %H:%M-%H-%M", :strftime)
#            {:ok, v}
#            String.length(v) > 15 ->
#              String.replace(v, ~r/ /)
#              Timex.parse(v, "%Y-%m-%d %a %H:%M", :strftime)
#            String.length(v) > 10 -> Timex.parse(v, "%Y-%m-%d %a", :strftime)
#            String.length(v) == 10 -> Timex.parse(v, "%Y-%m-%d", :strftime)
#        end
#        {k, date}
#    end
#  end) |> Enum.into(%{})
#  Map.merge(t1, new_dates)
#end)


# this would be ready for insert, but we need to do a version compare
Enum.at(current_objects, 3)
tmp = Ttl.Things.get_versions_of_objects(doc_id |> Ecto.UUID.dump() |> elem(1))
IO.inspect tmp
stored_objects = Enum.map(tmp, fn([id, ver]) ->
     {:ok, id} = Ecto.UUID.load(id)
     {id, ver}
end) |> Enum.into(%{})

IO.inspect stored_objects
#- current_object has no version or id -> it shouldn't be stored
#  - stored_object doesn't exist. Perfect
#  - can't compare even if it identical
#- current_object has version AND id
#  - stored_object exists and is <= version. Perfect
#  - stored_object exists and is > version - what to do?
#    - force_update
#    - fail the object in particular, return the stored state
#    - merge the changes - not building this right now - org-mode doesn't support crdt anyway

# do the compare and generate a list of objects for Ecto.insert_all
{good, bad} = Enum.split_with(current_objects, fn(x) ->
  cond do
    stored_objects[x.id] == nil -> true
    x.version >= stored_objects[x.id] -> true
    true -> false
  end
end)
good
attrs = Enum.at(current_objects, 3)
attrs = Enum.at(good, 3)
Ttl.Things.Object.changeset(%Ttl.Things.Object{}, attrs)
t1 = Enum.map(good, fn(x) ->
  Ttl.Things.Object.changeset(%Ttl.Things.Object{}, x)
end)
{good2, bad2} = Enum.split_with(t1, &(&1.valid?))
length(good2)
length(bad2)
Enum.at(bad2, 0)
tmpdate = Enum.at(good, 3).closed
|> Timex.parse("{YYYY}-{0M}-{D}")
Timex.parse("{YYYY}-{MM}-{DD} ")
Timex.Parse.DateTime.Parser.parse("2014-07-29 00:30:41.196-02:00", "{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
Timex.Parse.DateTime.Parser.parse("2014-07-29 00:30:41.196-02:00", "{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
Date.from_iso8601(tmpdate)
t1
String.replace(tmpdate, ~r/(Mon|Tue|Wed|Thu|Fri|Sat|Sun) /, "") |> Timex.Parse.DateTime.Parser.parse("{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
Ttl.Things.create_or_update_objects(good)
# now do the insert_all 

IO.inspect stored_objects["3b034419-4a16-4f8a-8d0d-52ebb494678f"]
List.last(current_objects)
id = "2e7ee139-f3b3-4d29-af37-7aad012f5f23"

o1 = Enum.at(current_objects, 3) 
o2 = Map.take(o1, [:deadline, :scheduled, :closed])  |> Enum.map(fn({k,v}) ->
  case v do
    nil -> {k,v}
    v -> {k, String.replace(v, ~r/ (Mon|Tue|Wed|Thu|Fri|Sat|Sun)/, "")}
  end
end)
o1
o2

{:ok, date} = Timex.Parse.DateTime.Parser.parse(o2[:closed], "{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
date
import Ecto.DateTime
Ecto.DateTime.cast(date)
Enum.into( o2, %{})
Map.merge(o1, Enum.into( o2, %{}))

### Parsing date regex

dates = ["2016-06-01 Wed 9:30-17:00 +1w", "2016-06-01 Wed 9:30-17:00", "2016-06-01 Wed 9:00", "2016-06-01 Wed 09:00", "2016-08-13 Sat 22:50", "2016-08-03", "2016-08-03 9:00", "2016-08-03 Wed 9:00"]
r = Regex.named_captures(~r/^(?<year>[\d]{4})\s*(?<state>[A-Z]*?)\s+(?<pri>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, Enum.at(dates,0))
r = Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*/, Enum.at(dates,0))
Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2})?)/, x) } end)
Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*/, x) } end)
Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*(?<interval>\+([\d][\w]))?/, x) } end)
r

### bad date parsing attempt
current_objects 
Timex.parse("2016-06-01 Wed 9:00-17:00", "%Y-%m-%d %a %H:%M-%H:%M", :strftime)
Timex.parse("2016-06-01 Wed 9:00", "%Y-%m-%d %a %H:%M", :strftime)
Enum.at(current_objects, 3).scheduled |> Timex.Parse.DateTime.Parser.parse("{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
Enum.at(current_objects, 3).scheduled |> Timex.Parse.DateTime.Parser.parse("{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
Enum.at(current_objects, 3).closed |> Timex.parse("%Y-%m-%d %a", :strftime)
Enum.at(current_objects, 3).closed |> Timex.parse("%Y-%m-%d %a %H:%M", :strftime)
Timex.parse("2016-06-10 Fri 09:00-17:00", "%Y-%m-%d %a %H:%M", :strftime)
ordered_object_ids = Enum.map(current_objects, &(Map.get(&1, :id)) )
