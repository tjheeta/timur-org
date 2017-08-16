defmodule Ttl.Parse do
  # TODO - @timestamps_opts [type: :utc_datetime]
  # TODO - user timezones
  defmodule Blank,              do: defstruct lnb: 0, line: "", content: "", inside_code: false
  defmodule Heading,            do: defstruct lnb: 0, line: "", level: 1, content: "", pri: "", state: "", tags: []
  # many to many table against heading
  defmodule Planning,           do: defstruct lnb: 0, line: "", level: 1, content: "", closed: nil, scheduled: nil, deadline: nil
  # many to many table against heading
  defmodule PropertyDrawer,     do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule LogbookDrawer,      do: defstruct lnb: 0, line: "", level: 1, content: []
  defmodule Section ,           do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule End,                do: defstruct lnb: 0, line: "", level: 1, key: "", value: ""
  defmodule Unknown,            do: defstruct lnb: 0, line: "", content: "", parent: ""

  defmodule Object do
    defstruct level: 1, title: "", content: "", closed: nil, scheduled: nil, scheduled_repeat_interval: nil, scheduled_duration: nil, deadline: nil, state: "", pri: "", version: 1, defer_count: 0, min_time_needed: 5, time_spent: 0, permissions: 0, tags: "", subobjects: []
  end
  defmodule Document do
    defstruct name: "", objects: []
  end

  # modes are default, force
  def doit(file, attrs \\ %{mode: "default"}) do
    # helper functions
    f_generate_id = fn ->
      {:ok, id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
      id
    end
    # TODO - fix the version update
    f_generate_version = fn -> 1 end

    f_compare_object_versions = fn(parsed_objects, db_objects) ->
      {objects_to_update, objects_with_conflict} = Enum.split_with(parsed_objects, fn(x) ->
        cond do
          db_objects[x.id] == nil -> true
          x.version >= db_objects[x.id] -> true
          true -> false
        end
      end)
    end

    # TODO - change to multi / handle two separate transactions
    # This will need to be done in Ttl.Things
    # pass on the objects_to_update_valid and create the array, etc
    f_update_database = fn(document, objects_to_update)  ->
      # Actually update the db now - two transactions
      objects = Enum.map(objects_to_update, fn(x) -> x.changes end)
      ordered_object_ids = Enum.map(objects, &(Map.get(&1, :id)) )
      Ttl.Things.create_or_update_objects(objects)
      Ttl.Things.update_document(document, %{objects: ordered_object_ids} )
    end

    # parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org")

    # Can't use the file name as the indicator as the thing could move around on fs
    parsed_doc = parse(file)

    parsed_doc = Map.put_new_lazy(parsed_doc, :id, f_generate_id)

    db_doc = case Ttl.Things.get_document(parsed_doc.id) do
               {:ok, x} -> x
               _ ->
                 {:ok, result} = Map.from_struct(parsed_doc)
                 |> Map.take([:id, :name])
                 |> Ttl.Things.create_document()
                 result
             end

    # Add versions and document_id to the parsed objects
    parsed_objects = Enum.map(parsed_doc.objects, fn(x) ->
      Map.from_struct(x)
      |> Map.put_new_lazy(:id, f_generate_id)
      |> Map.put_new_lazy(:version, f_generate_version )
      |> Map.put_new(:document_id, db_doc.id)
    end)

    # TODO - I'm sure this is not how to deal with binary_ids
    db_objects = db_doc.id |> Ecto.UUID.dump() |> elem(1)
    |> Ttl.Things.get_versions_of_objects
    |> Enum.map(fn([id, ver]) ->
      {:ok, id} = Ecto.UUID.load(id)
      {id, ver}
    end)
    |> Enum.into(%{})

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

    # {objects_to_update, objects_with_conflict} = Enum.split_with(parsed_objects, fn(x) ->
    #  cond do
    #    db_objects[x.id] == nil -> true
    #    x.version >= db_objects[x.id] -> true
    #    true -> false
    #  end
    #end)

    {objects_to_update, objects_with_conflict} = cond do
      attrs.mode == "force" -> {parsed_objects, []}
      true -> f_compare_object_versions.(parsed_objects, db_objects)
    end

    # Now put it through the changeset to make sure everything is valid
    {objects_to_update_valid, objects_update_invalid} =
     Enum.map(objects_to_update, fn(x) ->
       Ttl.Things.Object.changeset(%Ttl.Things.Object{}, x)
     end)
     |> Enum.split_with(&(&1.valid?))
    # get only the id's and titles for the invalid ones to pass back
    objects_update_invalid = Enum.map(objects_update_invalid, fn(x) -> {x.changes["id"], x.changes["title"]} end)

    # default - update everything valid - send back the id's with conflict and invalid
    {:ok, db_doc} = f_update_database.(db_doc, objects_to_update_valid)
    {:ok, db_doc, objects_update_invalid ++ objects_with_conflict}
  end

  def parse(file) do
    #s = File.stream!("/home/tjheeta/org/notes.org",  [:read, :utf8], :line)
    s = File.stream!(file,  [:read, :utf8], :line)
    data = Enum.reduce(s, [], fn(line, acc) ->
       [line | acc ]
    end)
    |> Enum.reverse
    data = Enum.zip(data, 1..Enum.count(data)+1)

    # first pass identify all the headers, planning, propertydrawers
    Enum.map(data, fn({line, lnb}) -> typeof({line, lnb}) end)
    |> build_ast([])
    # needs to have an id also
    |> create_document(%Document{name: file})
  end

  def slurp_until([], _, _, _, acc, ast) do
      build_ast([], [acc | ast])
  end

  # this assumes the accumulator is a struct with a content field
  def slurp_until([h | t] = data, func_end, func_acc, skip_end_line, acc, ast) do
    if func_end.(h) do
      case skip_end_line do
        true -> build_ast(t, [acc | ast])
        false -> build_ast(data, [acc | ast])
      end
    else
      tmp = func_acc.(acc.content , h.line)
      slurp_until(t, func_end, func_acc, skip_end_line, %{acc | content: tmp}, ast)
    end
  end

  def build_ast([], ast) do
    ast |> Enum.reverse
  end

  # Slurping the properties
  def build_ast([%Heading{} = s_head, %Planning{} = s_plan, %PropertyDrawer{} = s_prop| t], ast) do
    slurp_until(t, &(&1.line =~ ~r/:END:/), &(&1 <> &2), true,  s_prop, [s_plan, s_head | ast ])
  end

  def build_ast([%Heading{} = s_head, %Planning{} = s_plan | t], ast) do
    build_ast(t, [s_plan, s_head | ast])
  end

  def build_ast([%Heading{} = s_head, %PropertyDrawer{} = s_prop| t], ast) do
    build_ast(t, [s_prop, s_head | ast])
  end

  def build_ast([%Heading{} = s_head |  t], ast) do
    build_ast(t, [s_head | ast])
  end

  # Slurping the logbook
  def build_ast([%LogbookDrawer{} = s_log |  t], ast) do
    slurp_until(
      t,
      &(&1.line =~ ~r/:END:/),
      &( [ &2 | &1 ] ),
      true,
      s_log,
      ast
    )
  end

  # Slurping into section until we find something else
  def build_ast([h | t], ast) do
    slurp_until(
      t,
      &(&1.__struct__ != Ttl.Parse.Unknown), # stop at unknown
      &(&1 <> &2),                           # concatenate
      false,                                 # don't skip the end line
      %Section{lnb: h.lnb, content: h.line},
      ast
    )
  end

  def create_document(ast) do
    create_document(ast, %Document{})
  end

  def create_document([], doc) do
    %{ doc | objects: (Enum.reverse(doc.objects ) ) }
  end

  def create_document([h | t], doc) do
    cond do
      # If it's a heading, create an object and add it to the list of current objects
      h.__struct__ == Ttl.Parse.Heading ->
        obj = %Object{title: h.content, level: h.level, pri: h.pri, state: h.state, tags: h.tags}
        create_document(t, %{doc | objects: [obj | doc.objects]} )

      # If the list of objects is empty, even if it's not a heading, add it to the list
      doc.objects == [] ->
        create_document(t , %{doc | objects: [h | doc.objects]})

      true ->
        # not a heading, we need to update the heading to include planning, logbook, section, or append to list
        index = Enum.find_index(doc.objects, fn(x) -> x.__struct__ == Ttl.Parse.Object end)
        current_object = Enum.at(doc.objects, index)
        current_object = cond do
          h.__struct__ == Ttl.Parse.Planning ->
            %{current_object | closed: h.closed, scheduled: h.scheduled, deadline: h.deadline}
          h.__struct__ == Ttl.Parse.Section ->
            %{current_object | content: (current_object.content <> h.content) }
          h.__struct__ == Ttl.Parse.PropertyDrawer ->
            %{current_object | subobjects: [ h  | current_object.subobjects ] }
          h.__struct__ == Ttl.Parse.LogbookDrawer ->
            %{current_object | subobjects: [ h  | current_object.subobjects ] }
          true -> current_object
        end
        # replace the current object in the doc
        doc_objects = List.replace_at(doc.objects, index, current_object)
        create_document(t, %{doc | objects: doc_objects})
    end
  end

  def typeof({line,lnb}) do
    cond do
      r = Regex.named_captures(~r/^(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<pri>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, line)  ->
        r = r |> Map.update!("title", &(String.strip/1))
        %Heading{content: r["title"], level: String.length(r["stars"]),
          pri: r["pri"], state: r["state"], tags: r["tags"], lnb: lnb, line: line}

      r = Regex.named_captures(~r/^(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<pri>(\[#[A-Z]\])?)\s*(?<title>.+)\s*/, line) ->
        r = r |> Map.merge(%{"tags" => ""}) |> Map.update!("title", &(String.strip/1))
        %Heading{content: r["title"], level: String.length(r["stars"]), 
          pri: r["pri"], state: r["state"], tags: r["tags"], lnb: lnb, line: line}


      # TODO - There is probably a way to capture all three planning at once
      Regex.named_captures(~r/(?<keyword>(DEADLINE|SCHEDULED|CLOSED)):/, line) ->
        r = (Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<closed>[^>\]]+)([\]>]))/, line) || %{} )
        r = (Regex.named_captures(~r/(DEADLINE:\s*([\[<])(?<deadline>[^>\]]+)([\]>]))/, line) || %{}) |> Map.merge(r)
        r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled_start>[^>\]]+)([\]>])((--)([\[<])(?<scheduled_end>[^>(CLOSED|DEADLINE)\]]+)([\]>]))?)/, line) || %{}) 
        # closed and deadline can be turned directly into Ecto.DateTime
        # scheduled will need to be split into scheduled (datetime), scheduled_end (datetime), and scheduled_interval (string)
        # http://orgmode.org/manual/Timestamps.html#Timestamps
        # the repeat scheduling over multiple days doesn't actually work in org-mode
        # CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00+1w>--<2016-06-02 9:00-17:00> DEADLINE: <bla>

        # The following regexp correctly parses all of the below
        #dates = ["2016-06-01 Wed 9:30-17:00 +1w", "2016-06-01 Wed 9:30-17:00", "2016-06-01 Wed 9:00", "2016-06-01 Wed 09:00", "2016-08-13 Sat 22:50", "2016-08-03", "2016-08-03 9:00", "2016-08-03 Wed 9:00"]
        #Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*(?<interval>\+([\d][\w]))?/, x) } end)

        date_format_regexp  = ~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<hour_end>[\d]{1,2}):(?<minute_end>[\d]{2}))?\s*(?<repeat_interval>\+([\d][\w]))?/

        # schedule can have a range of dates and also a range of times
        # TODO - for tag-based calendar scheduling, need a range of intervals. 
        # TODO - same problem will occur for bin-packing later, but let's get the rough work done first - single date
        { scheduled_start,
          scheduled_start_duration,
          scheduled_repeat_interval 
        } = case Map.get(r, "scheduled_start") do
              nil -> { nil, 0, 0 }
              x ->

                # To cast to Ecto.Datetime, the hour/minute needs to be non-zero
              {:ok, date} = Regex.named_captures( date_format_regexp, x)
                |> Map.update("hour", 0, fn(v) -> if v == "", do: 0, else: v end)
                |> Map.update("minute", 0, fn(v) -> if v == "", do: 0, else: v end)
                |> Ecto.DateTime.cast
                date = Ecto.DateTime.to_iso8601(date)

              {date, 0, 0 }
            end

        deadline = case Map.get(r, "deadline") do
                     nil -> nil
                     x -> Regex.named_captures( date_format_regexp, Map.get(r, "deadline")) |> Ecto.DateTime.cast
                   end
        closed = case Map.get(r, "closed") do
                   nil -> nil
                   x -> Regex.named_captures( date_format_regexp, Map.get(r, "deadline")) |> Ecto.DateTime.cast
                 end

        %Planning{line: line, lnb: lnb, scheduled: scheduled_start, deadline: deadline, closed: closed}

      line =~ ~r/^:PROPERTIES:/ ->
        %PropertyDrawer{line: line, lnb: lnb}

      line =~ ~r/^:LOGBOOK:/ ->
        %LogbookDrawer{line: line, lnb: lnb}

      line =~ ~r/^:END:/ ->
        %End{line: line, lnb: lnb}

      true -> 
        %Unknown{line: line, lnb: lnb}
    end
  end

  # used in tests only
  def typeof(line) do
    cond do
      line =~ ~r/^\s*$/ ->
        %Blank{}
      #(res = Regex.named_captures(~r/(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<priority>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, line)) != nil ->
      res = Regex.named_captures(~r/^(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<priority>(\[#[A-Z]\])?)\s*(?<title>.+)\s+(?<tags>(:.*:))/, line) ->
         res |> Map.update!("title", &(String.strip/1))
      (res = Regex.named_captures(~r/^(?<stars>[\*]+)\s*(?<state>[A-Z]*?)\s+(?<priority>(\[#[A-Z]\])?)\s*(?<title>.+)\s*/, line)) != nil ->
         res |> Map.merge(%{"tags" => ""}) |> Map.update!("title", &(String.strip/1))
         #%Heading{level: String.length(res["stars"])}
    end
  end


end
