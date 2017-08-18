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
attrs.scheduled
Ecto.DateTime.cast(attrs.scheduled)
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
d =  "CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00 +1w>--<2016-06-02 9:00-17:00> DEADLINE: <bla>"
d =  "CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00> DEADLINE: <bla>"
d =  "CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00 +1w> DEADLINE: <bla>"
r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled>[^>\]]+)([\]>])((--)([\[<])(?<scheduled2>[^>(CLOSED|DEADLINE)\]]+)([\]>]))?)/, d) || %{}) 

dates = ["2016-06-01 Wed 9:30-17:00 +1w", "2016-06-01 Wed 9:30-17:00", "2016-06-01 Wed 9:00", "2016-06-01 Wed 09:00", "2016-08-13 Sat 22:50", "2016-08-03", "2016-08-03 9:00", "2016-08-03 Wed 9:00"]
r = Regex.named_captures(~r/^(?<year>[\d]{4})\s*(?<state>[A-Z]*?)\s+(?<pri>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, Enum.at(dates,0))
r = Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*/, Enum.at(dates,0))
Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2})?)/, x) } end)
Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*/, x) } end)
r = Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*(?<interval>\+([\d][\w]))?/, x) } end)
Enum.at(r,0) |> elem(1) |> Ecto.DateTime.cast

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



{:ok, d1} = %{"day" => "05",  "month" => "07", "year" => "2017", "hour" => 0, "minute" => 0} |> Ecto.DateTime.cast 
DateTime.from(d1)
DateTime.from_naive(d1, "Etc/UTC")
DateTime.from_naive()
Ecto.DateTime.to_iso8601(d1) 
DateTime.to_unix(%DateTime{calendar: Calendar.ISO, day: 2, hour: 11, microsecond: {0, 0}, minute: 42, month: 2, second: 46, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"})

x = Regex.named_captures(~r/a(?<foo>b)c(?<bar>d)?/, "abce")
{_, x2} = Map.get_and_update(x2, "bar", fn(v) -> if v == "", do: {v,0}, else: {v,v} end)
x2 = %{"bar" => 3, "foo" => "b"}
x2
x2 = Map.update(x2, "bar", 0, fn(v) -> if v == "", do: 0, else: v end)
x2



## Last working state

d = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
# what is my document_id?

{:ok, doc_id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
Map.from_struct(d) |> Map.take([:id, :name]) 
{:ok, tmpdoc} = Map.from_struct(d) |> Map.take([:id, :name]) |> Ttl.Things.create_document()
d = Map.put_new(d, :id, doc_id)
doc_id = tmpdoc.id
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
ordered_object_ids = Enum.map(current_objects, &(Map.get(&1, :id)) )
Enum.at(current_objects, 10)
Enum.at(ordered_object_ids, 10)
tmp = Ttl.Things.get_versions_of_objects(doc_id |> Ecto.UUID.dump() |> elem(1))
tmp
stored_objects = Enum.map(tmp, fn([id, ver]) ->
     {:ok, id} = Ecto.UUID.load(id)
     {id, ver}
end) |> Enum.into(%{})
stored_objects

### Versioning notes
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

tmpdoc.id
t1 = Enum.map(good, fn(x) ->
  Ttl.Things.Object.changeset(%Ttl.Things.Object{}, x)
end)
{good2, bad2} = Enum.split_with(t1, &(&1.valid?))
length(good2)
length(bad2)
IO.inspect Enum.at(good2, 0)

data = good2
# now do the insert_all 
Enum.map(data, fn(x) -> x.changes end) |> Ttl.Things.create_or_update_objects()
ordered_object_ids
# Add all the objects in order to the document
Ttl.Things.update_document(tmpdoc, %{objects: ordered_object_ids} )
tmpdoc
# PSQL select * from things_documents where id = uuid('f6271af8-df62-4f3f-95a0-b86e91cca276');  

'00d7415d-847b-4f75-8745-7d9f5bdab02e' |> Ecto.UUID.load
{:ok, id} = Ecto.UUID.dump("00d7415d-847b-4f75-8745-7d9f5bdab02e") 
id
Ttl.Things.get_object!(id)
Ttl.Things.get_object!('00d7415d-847b-4f75-8745-7d9f5bdab02e')
Ttl.Things.get_object!("00d7415d-847b-4f75-8745-7d9f5bdab02e")
#Enum.each(data, fn(x) ->
#  IO.inspect x.changes
#  Ttl.Things.create_or_update_objects([x.changes])
#  end)


elem(x,2)
|> Enum.at(0)
Ttl.Things.get_object!("a97c6bb7-c305-454a-aea5-3e65e5aa8ac2")
Ecto.Multi.new 

a = %{mode: "default"}
a[:mode]

d.id
d.metadata
d.objects
Ecto.Repo.

alias Ttl.Things.Object
alias Ttl.Repo
import Ecto.Query

#select: %{id: o.id, data: %{level: o.level, content: o.content, scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
#select: %{id: fragment("cast(id as text)"), data: %{level: o.level, content: o.content, scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
#select: %{o.id: %{level: o.level, content: o.content, scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
#select: %{fragment("cast(id as text)"): %{level: o.level, content: o.content, scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
d.id

x = Enum.at(data,3)
x = Enum.at(data, 0)
data = Enum.reduce(content, "", fn(x, acc) ->
  Map.keys(x)
  x2 = Map.to_list(x)
  [closed: closed, content: content, deadline: deadline, level: level, scheduled: scheduled, title: title] = Map.to_list(x)
  [ level, title, state, priority, content, scheduled, closed, deadline, version ] = x  # |> Enum.map(fn(x) ->
    case x do
      { date, {h, m, d, _}} -> {date, {h, m, d}}
      _ -> x
    end 
    end)


  f_db_date_to_string = fn(date, bracket ) ->
    { big, {h, m, d, _}}  = date
    date = {big, {h,m,d}} |> Ecto.DateTime.from_erl |> Ecto.DateTime.to_string 
    case bracket do
      "[" -> "[" <> date <> "] "
      "]" -> "[" <> date <> "] "
      "[]" -> "[" <> date <> "] "
      :square -> "[" <> date <> "] "
      _ -> "<" <> date <> "> "
    end
  end

f_object_to_string = fn(data) ->
  [ level, title, state, priority, content, scheduled, closed, deadline, version ] = data
  acc = ""
  str_level = String.duplicate("*", level)
  acc = acc <> str_level <> " "
  acc = if state, do: acc <> state <> " ", else: acc
  #acc = if title, do: acc <> String.replace(title, ~r/\r|\n/, "") <> " ", else: acc
  acc = if title, do: acc <> title <> " ", else: acc
  acc = if priority, do: acc <> priority <> " ", else: acc
  acc = String.trim_trailing(acc, " ") <> "\n"

  planning_string = ""
  planning_string = planning_string <> if closed,  do: "CLOSED: " <> f_db_date_to_string.(closed, :square), else: ""
  planning_string = planning_string <> if deadline,  do: "DEADLINE: " <> f_db_date_to_string.(deadline, "[]"), else: ""
  scheduled
  planning_string = planning_string <> if scheduled,  do: "SCHEDULED: " <> f_db_date_to_string.(scheduled, "<"), else: ""
  planning_string = planning_string <> (if String.length(planning_string) > 5, do: "\n", else: "")
  acc = acc <> planning_string 
  #acc = String.trim_trailing(acc, " ") <> "\n"
  acc = if content, do: acc <> content, else: acc
  acc 
end

d = Ttl.Things.get_document!("b6e644d8-cb01-4a2d-8c32-9d4e53f1e3ac")


Enum.at(data,1) |> f_object_to_string.()
data
d.metadata
str = ""
str = Enum.reduce( d.metadata, "", fn({k,v}, acc) ->  acc <> "#+#{k}: #{v}\n" end)
str = Enum.reduce(data, str, fn(x, acc) ->
  acc <> f_object_to_string.(x)
end)
File.write("/tmp/hello",str )

str
IO.puts(str)
t = Enum.at(data, 15) |> Enum.at(1)
"*** " <> t <> "\n"
  case x do  
    [level, title, content, scheduled ]
  end
  case x  do
    [nil, content: content, deadline: deadline, level: 1, scheduled: nil] -> IO.inspect "HERE"
    [closed: nil, content: content, deadline: deadline, level: 0, scheduled: nil, title: title] -> IO.inspect "HERE2"
  end
  acc = case x.content do
    nil -> x.content
  end
  IO.inspect x.content
  acc <> x.content
end)

Enum.at(content, 3)
f_query2 = fn(document_id) ->
  {:ok, document_id}= Ecto.UUID.dump(document_id)
  q = from o in "things_objects",
    where: o.document_id == ^document_id,
    select: %{fragment("cast(id as text)") => %{level: o.level, title: o.title, content: o.content, scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
    #select: %{fragment("cast(id as text)") => map(Object, [o.level, o.content, o.scheduled, o.closed,  o.deadline])}
  Repo.all(q) |> Enum.reduce(%{}, fn(x, acc) -> Map.merge(acc, x) end)
end
data = f_query2.(d.id) 
Map.keys(data2)
data2["78281328-a18b-471b-b5f5-96cfdfc2295a"]
Map.get(data2, "78281328-a18b-471b-b5f5-96cfdfc2295a")
d.objects
data
content = for id <- d.objects, do: [data[id].title, data[id].content]
tmp 
content = for id <- d.objects, Map.get(data, id), do: Map.get(data, id)
Enum.at(content, 3)
posts |> Enum.map(&(&1.id)) |> IO.inspect
data |> Map.keys

f_query = fn(document_id) ->
  {:ok, document_id}= Ecto.UUID.dump(document_id)
  q = from o in "things_objects",
    where: o.document_id == ^document_id,
    select: [o.id , o.level, o.content, o.scheduled, o.closed, o.deadline]
  result = Repo.all(q) |> Enum.reduce(%{}, fn(row, acc) ->
    [id | t] = row
    {:ok, id} = Ecto.UUID.load(id)
    Map.put_new(acc, id, t)
  end)
end
data = f_query.(d.id)
Enum.reduce(d.objecs, "", fn(x, acc) ->
  IO.inspect x
  IO.inspect data[x]
end)

q = f_query.(d.id)
Repo.all(q)
Repo.all(Object)


# debugging
parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
db_doc = Ttl.Things.get_document(parsed_doc.id) 
IO.inspect parsed_doc.id
Ttl.Things.get_document!(parsed_doc.id)

{:ok, db_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/notes.org")
notes_id = db_doc.id
{:ok, db_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/meditation.org")
med_id = db_doc.id
{:ok, db_doc, invalid}  = Ttl.Parse.doit("/home/tjheeta/org/adil-reference.org")
adil_id = db_doc.id

data = Ttl.Parse.regenerate(notes_id)
data = Ttl.Parse.regenerate(adil_id)
data = Ttl.Parse.regenerate(med_id)
Ecto.UUID.dump(adil_id)


tmpdoc = Ttl.Things.get_document!(adil_id)
f_generate_metadata.(tmpdoc.metadata)
tmpobjid = Ttl.Things.get_document!(adil_id).objects |> Enum.at(0)
Ttl.Things.get_object!(tmpobjid)

# test id parsing
parsed_doc = Ttl.Parse.parse("/tmp/recurse")
parsed_doc.metadata
parsed_doc.id

parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
parsed_doc.metadata
parsed_doc.id

# propertydrawer parsing test
parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org")
Enum.at(parsed_doc.objects, 68) # this is the propertiesdrawer for Indian phone renew
parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/meditation.org")
Enum.at(parsed_doc.objects, 1) 

{:ok, db_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/notes.org")
Enum.at(db_doc.objects, 68) |> Ttl.Things.get_object!

{:ok, med_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/meditation.org")
x = Enum.at(med_doc.objects, 1) |> Ttl.Things.get_object! 
x.properties 
Enum.reduce(x.properties, ":PROPERTIES:\n", fn({k,v}, acc) ->
  ":#{k}:    #{v}"
end)

## Testing
{:ok, db_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/notes.org")
data = Ttl.Parse.regenerate(notes_id)

{:ok, r_doc, invalid} = Ttl.Parse.doit("/tmp/recurse.org")
{:ok, r_doc, invalid} = Ttl.Parse.doit("/tmp/hello")
recurse_id = r_doc.id
data = Ttl.Parse.regenerate(recurse_id)

{:ok, sre_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/sreprep.org")
{:ok, sre_doc, invalid} = Ttl.Parse.doit("/tmp/sreprep-recurse.org")
sre_id = sre_doc.id
sre_doc.metadata
data = Ttl.Parse.regenerate(sre_id)

{:ok, med_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/meditation.org")
med_id = med_doc.id
data = Ttl.Parse.regenerate(med_id)

{:ok, a_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/adil-reference.org")
a_id = a_doc.id
data = Ttl.Parse.regenerate(a_id)

{:ok, xdoc, invalid} = Ttl.Parse.doit("/home/tjheeta/repos/self/ttl/README.org")
xid = xdoc.id
data = Ttl.Parse.regenerate(xid)

parsed_doc = Ttl.Parse.parse("/tmp/recurse.org")
|> Enum.filter(&(&1.__struct__ == Ttl.Parse.PropertyDrawer))
parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org") |> Enum.filter(&(&1.__struct__ == Ttl.Parse.PropertyDrawer))
parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/meditation.org") |> Enum.filter(&(&1.__struct__ == Ttl.Parse.PropertyDrawer))
parsed_doc.id
{:ok, random_id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
%Ttl.Things.Document{} =
 huh =  Ttl.Things.get_document(parsed_doc.id)
huh.id
{:ok, x} = Ttl.Things.get_document(random_id)
{:ok, recurse_doc, invalid} = Ttl.Parse.doit("/tmp/recurse.org")
recurse_id = recurse_doc.id
x = Ttl.Things.get_document(recurse_doc.id)
recurse_doc.metadata
Ttl.Things.get_object!(x.objects |> Enum.at(3))
data = Ttl.Parse.regenerate(recurse_id)

{:ok, recurse_doc, invalid} = Ttl.Parse.doit("/tmp/recurse2.org")
recurse_id = recurse_doc.id
data = Ttl.Parse.regenerate(recurse_id)
{:ok, recurse_doc, invalid} = Ttl.Parse.doit("/tmp/recurse3.org")
recurse_id = recurse_doc.id
data = Ttl.Parse.regenerate(recurse_id)

%Ttl.Parse.PropertyDrawer{content: ":LAST_REPEAT: [2017-08-15 Tue 05:09]\n:STYLE:    habit\n", level: 1, line: ":PROPERTIES:\n", lnb: 3}
** (RuntimeError) oops
(ttl) lib/ttl/parse/parse.ex:324: Ttl.Parse.create_document/2
l = ":LAST_REPEAT: [2017-08-15 Tue 05:09]\n:STYLE:    habit\n"
String.split(l, "\n") |>Enum.filter(&(&1 != "")) |> Enum.map(fn(x) ->
  r = Regex.named_captures(~r/^:(?<key>[A-Z_-]*):\s+(?<value>.+)/, x)
  %{r["key"] => r["value"]}
end)

String.split(l, "\n") 

String.split(l, "\n") |>Enum.filter(&(&1 != "")) |> Enum.reduce(%{}, fn(x,acc) ->
  r = Regex.named_captures(~r/^:(?<key>[A-Z_-]*):\s+(?<value>.+)/, x)
  Map.merge(acc,%{r["key"] => r["value"]})
end)


### Testing adding / deleting entries / reordering / re-leveling manually
{:ok, db_doc, invalid} = Ttl.Parse.doit("/home/tjheeta/org/notes.org")
data = Ttl.Parse.regenerate_to_file("/tmp/notes.org", db_doc.id)
{:ok, db_doc, invalid} = Ttl.Parse.doit("/tmp/notes.org")
length(db_doc.objects)
data = Ttl.Parse.regenerate_to_file("/tmp/notes2.org", db_doc.id)

