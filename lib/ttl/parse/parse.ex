defmodule Ttl.Parse do
  # TODO - @timestamps_opts [type: :utc_datetime]
  # TODO - user timezones
  defmodule Blank,              do: defstruct lnb: 0, line: "", content: "", inside_code: false
  defmodule Heading,            do: defstruct lnb: 0, line: "", level: 1, content: "", pri: "", state: "", tags: []
  # many to many table against heading
  defmodule Planning,           do: defstruct lnb: 0, line: "", level: 1, content: "", closed: nil, deadline: nil, scheduled: nil, scheduled_repeat_interval: nil, scheduled_duration: nil
  # many to many table against heading
  defmodule PropertyDrawer,     do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule LogbookDrawer,      do: defstruct lnb: 0, line: "", level: 1, content: []
  defmodule Section ,           do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule End,                do: defstruct lnb: 0, line: "", level: 1, key: "", value: ""
  defmodule Unknown,            do: defstruct lnb: 0, line: "", level: 1, content: "", parent: ""

  defmodule Object do
    defstruct id: nil, level: 1, title: "", content: "", closed: nil, scheduled: nil, scheduled_repeat_interval: nil, scheduled_duration: nil, deadline: nil, state: "", pri: "", version: 1, defer_count: 0, min_time_needed: 5, time_spent: 0, permissions: 0, tags: "", properties: %{}, subobjects: []
  end
  defmodule Document do
    defstruct id: nil, name: "", metadata: [], objects: []
  end

  def regenerate_to_file(filename, string_uuid) do
    str = regenerate(string_uuid)
    File.write(filename, str)
  end
  def regenerate(string_uuid) do
    # probably quite a few faster and better ways to do this in the db
    # but not caring about performance quite yet
    # ttl_dev=# with x (id_list) as (select objects from things_documents) select o.id, o.title from things_objects o, x where id = any (x.id_list) order by array_position(x.id_list, o.id  );
    f_query = fn(document_id) ->
      import Ecto.Query
      q_struct = from o in "things_objects",
        where: o.document_id == ^document_id,
        select: %{fragment("cast(id as text)") =>
          [ fragment("cast(id as text)"), o.level, o.title, o.state, o.priority, o.content, o.properties, o.scheduled, o.closed, o.deadline, o.version ]
        }
      q_map = from o in "things_objects",
        where: o.document_id == ^document_id,
        select: %{fragment("cast(id as text)") =>
          %{level: o.level, title: o.title, content: o.content, properties: o.properties,
            scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
      q_all = from o in Ttl.Things.Object, 
      where: o.document_id == ^document_id
      Ttl.Repo.all(q_struct)
      |> Enum.reduce(%{}, fn(x, acc) -> Map.merge(acc, x) end)
    end
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
      [ id, level, title, state, priority, content, properties, scheduled, closed, deadline, version ] = data
      acc = ""
      str_level = String.duplicate("*", level)
      acc = if level > 0, do: acc <> str_level <> " ", else: acc
      acc = if state, do: acc <> state <> " ", else: acc
      acc = if title, do: acc <> title <> " ", else: acc
      acc = if priority, do: acc <> priority <> " ", else: acc
      acc = (if String.length(acc) > 5, do: String.trim_trailing(acc, " ") <> "\n", else: acc)

      planning_string = ""
      planning_string = planning_string <> if closed,  do: "CLOSED: " <> f_db_date_to_string.(closed, :square), else: ""
      planning_string = planning_string <> if deadline,  do: "DEADLINE: " <> f_db_date_to_string.(deadline, "[]"), else: ""
      planning_string = planning_string <> if scheduled,  do: "SCHEDULED: " <> f_db_date_to_string.(scheduled, "<"), else: ""
      planning_string = planning_string <> (if String.length(planning_string) > 5, do: "\n", else: "")
      acc = acc <> planning_string

      property_string = "PREFIX_OBJ_ID: #{id}\n:PREFIX_OBJ_VERSION: #{version}\n"
      property_string = 
      if properties && length(Map.keys(properties)) > 0 do
        Enum.reduce(properties, property_string, fn({k,v}, acc) ->
          str = ":#{k}:    #{v}\n"
          acc <> str
        end) 
      else
        property_string
      end
      property_string = ":PROPERTIES:\n:#{property_string}:END:\n"
      acc = acc <> property_string

      acc = if content, do: acc <> content, else: acc
    end

    f_generate_metadata = fn(document) ->
      acc = "#+PREFIX_DOC_ID:#{document.id}\n"
      acc = Enum.reduce( document.metadata, acc, fn({k,v}, acc) ->
          str = "#+#{k}: #{v}"
          if String.length(str) do
            acc <> str <> "\n"
          else
            acc
          end
      end)
    end

    # get the data for the file
    # TODO - need to add spec format and put these functions non anon
    {:ok, binary_uuid}= Ecto.UUID.dump(string_uuid)
    document = Ttl.Things.get_document!(string_uuid)
    unsorted_data = f_query.(binary_uuid)
    sorted_data = for id <- document.objects, do: unsorted_data[id]

    # now need to merge the file together
    str = f_generate_metadata.(document)
    str = str <> "\n" # Adding extra newline
    str = Enum.reduce(sorted_data, str, fn(x, acc) ->
      acc <> f_object_to_string.(x)
    end)
  end

  # modes are default, force
  def doit(file, attrs \\ %{mode: "default"}) do
    # helper functions
    f_maybe_add_id = fn(somemap) ->
      case Map.get(somemap, :id) do
        nil ->
          {:ok, id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
          Map.put(somemap, :id, id)
        _ -> somemap
      end
    end
    f_maybe_add_version = fn(somemap) ->
      case Map.get(somemap, :version) do
        nil ->
          Map.put(somemap, :version, 1)
        _ -> somemap
      end
    end

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
    |> f_maybe_add_id.()

    db_doc = case Ttl.Things.get_document(parsed_doc.id) do
               %Ttl.Things.Document{} = x -> x
               nil ->
                 {:ok, result} = Map.from_struct(parsed_doc)
                 |> Map.take([:id, :name, :metadata])
                 |> Ttl.Things.create_document()
                 result
             end

    # Add versions and document_id to the parsed objects
    parsed_objects = Enum.map(parsed_doc.objects, fn(x) ->
      Map.from_struct(x)
      |> Map.put_new(:document_id, db_doc.id)
      |> f_maybe_add_id.()
      |> f_maybe_add_version.()
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

  # returns a Document - doesn't do any extraneous additions to the file - only parsing
  def parse(file) do
    #s = File.stream!("/home/tjheeta/org/notes.org",  [:read, :utf8], :line)
    s = File.stream!(file,  [:read, :utf8], :line)
    data = Enum.reduce(s, [], fn(line, acc) ->
       [line | acc ]
    end)
    |> Enum.reverse
    data = Enum.zip(data, 1..Enum.count(data)+1)

    # need to identify top of file metadata
    {file_metadata, drop_count} = Enum.reduce_while(data, {%{}, 0}, fn({line, lnb}, {metadata, count}) ->
      if line =~ ~r/^#\+/ do
        r = Regex.named_captures(~r/^#\+(?<key>[A-Z-_]*?):\s*(?<value>.+)/, line)
        tmp = %{Map.get(r, "key") => Map.get(r, "value")}
        {:cont, {Map.merge(metadata, tmp), count + 1}}
      else
        {:halt, {metadata, count}}
      end
    end)
    # remove the file_metadata 
    data = Enum.drop(data, drop_count)

    # in addition, find all the next blank lines
    blank_count = Enum.reduce_while(data, 0, fn({line, lnb}, count) ->
      if String.trim(line) == "" do
        {:cont, count + 1}
      else
        {:halt, count}
      end
    end)
    data = Enum.drop(data, blank_count)

    # first pass identify all the headers, planning, propertydrawers
    # this builds all the individual elements from lines
    Enum.map(data, fn({line, lnb}) -> typeof({line, lnb}) end)
    # this creates elements - planning, propertydrawer, logbookdrawer, etc.
    |> create_elements([])
    # TODO - rename to consolidate_objects, creates obj from elements
    |> create_document(%Document{name: file, metadata: file_metadata, id: file_metadata["PREFIX_DOC_ID"]})
  end

  def slurp_until([], _, _, _, acc, ast) do
      create_elements([], [acc | ast])
  end

  # this assumes the accumulator is a struct with a content field
  def slurp_until([h | t] = data, func_end, func_acc, skip_end_line, acc, ast) do
    if func_end.(h) do
      case skip_end_line do
        true -> create_elements(t, [acc | ast])
        false -> create_elements(data, [acc | ast])
      end
    else
      tmp = func_acc.(acc.content , h.line)
      slurp_until(t, func_end, func_acc, skip_end_line, %{acc | content: tmp}, ast)
    end
  end

  def create_elements([], ast) do
    ast |> Enum.reverse
  end

  # Slurping the properties
  def create_elements([%Heading{} = s_head, %Planning{} = s_plan, %PropertyDrawer{} = s_prop| t], ast) do
    slurp_until(t, &(&1.line =~ ~r/:END:/), &(&1 <> &2), true,  s_prop, [s_plan, s_head | ast ])
  end

  def create_elements([%Heading{} = s_head, %Planning{} = s_plan | t], ast) do
    create_elements(t, [s_plan, s_head | ast])
  end

  def create_elements([%Heading{} = s_head, %PropertyDrawer{} = s_prop| t], ast) do
    slurp_until(t, &(&1.line =~ ~r/:END:/), &(&1 <> &2), true,  s_prop, [s_head | ast ])
  end

  def create_elements([%Heading{} = s_head |  t], ast) do
    create_elements(t, [s_head | ast])
  end

  # Slurping the logbook
  def create_elements([%LogbookDrawer{} = s_log |  t], ast) do
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
  def create_elements([h | t], ast) do
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

    # helper func
    f_convert_property_drawer_to_map = fn(content_string) ->
      # h = %Ttl.Parse.PropertyDrawer{content: ":LAST_REPEAT: [2017-08-15 Tue 05:09]\n:STYLE:    habit\n",
      # level: 1, line: ":PROPERTIES:\n", lnb: 3}
      String.split(content_string, "\n")
      |> Enum.filter(&(&1 != ""))
      |> Enum.reduce(%{}, fn(x,acc) ->
        r = Regex.named_captures(~r/^:(?<key>[A-Za-z_-]*):\s+(?<value>.+)/, x)
        Map.merge(acc,%{r["key"] => r["value"]})
      end)
    end

    # key_lookup should be a string, and key_to_update is either :id or :version 
    f_maybe_set_var_from_properties_map = fn(object, key_lookup, key_to_update) ->
      case Map.get(object.properties, key_lookup ) do
        nil -> object
        x ->
          new_properties = Map.delete(object.properties, key_lookup)
          res = Map.put(object, key_to_update, x)
          |> Map.put(:properties, new_properties)
      end

    end

    f_maybe_set_id_from_properties_map = fn(object) ->
      f_maybe_set_var_from_properties_map.(object, "PREFIX_OBJ_ID", :id)
    end
    f_maybe_set_version_from_properties_map = fn(object) ->
      f_maybe_set_var_from_properties_map.(object, "PREFIX_OBJ_VERSION", :version)
    end

    # find the latest object
    current_object_index = Enum.find_index(doc.objects, fn(x) -> x.__struct__ == Ttl.Parse.Object end)
    cond do
      # If it's a heading, create an object and add it to the list of current objects
      h.__struct__ == Ttl.Parse.Heading ->
        obj = %Object{title: h.content, level: h.level, pri: h.pri, state: h.state, tags: h.tags}
        create_document(t, %{doc | objects: [obj | doc.objects]} )

      # If the list of objects is empty, need to treat the start of file as special before the first heading
      # AFAIK - this is not a valid org-file
      # Two options:
      # 1) make an autogenerated heading object
      # 2) make a special start of file metadata object that we need to read in - which adds complications to reading the file
      # Going for option 1
      doc.objects == [] ->
        title = "Autogenerated title"
        h = Map.put(h, :title, title)
        h = Map.put(h, :level, 1)

        create_document(t , %{doc | objects: [h | doc.objects]})

      true ->
        # not a heading, we need to update the heading to include planning, logbook, section, or append to list
        current_object = Enum.at(doc.objects, current_object_index)
        current_object = cond do
          h.__struct__ == Ttl.Parse.Planning ->
            %{current_object | closed: h.closed, scheduled: h.scheduled, deadline: h.deadline}
          h.__struct__ == Ttl.Parse.Section ->
            %{current_object | content: (current_object.content <> h.content) }
          h.__struct__ == Ttl.Parse.PropertyDrawer ->
            # set the properties component and set the id/version if they exist
            %{current_object | properties: f_convert_property_drawer_to_map.(h.content) }
            |> f_maybe_set_id_from_properties_map.()
            |> f_maybe_set_version_from_properties_map.()
          h.__struct__ == Ttl.Parse.LogbookDrawer ->
            %{current_object | subobjects: [ h  | current_object.subobjects ] }
          true -> current_object
        end

        # replace the current object in the doc
        doc_objects = List.replace_at(doc.objects, current_object_index, current_object)
        create_document(t, %{doc | objects: doc_objects})
    end
  end

  @spec helper_f_capture_date(string) :: {NaiveDateTime,  integer, string }
  def helper_f_capture_date(date) do
    # To cast to Ecto.Datetime, the hour/minute needs to be non-zero
    f_capture_date = fn(date) ->
      # The following regexp correctly parses all of the below
      #dates = ["2016-06-01 Wed 9:30-17:00 +1w", "2016-06-01 Wed 9:30-17:00", "2016-06-01 Wed 9:00", "2016-06-01 Wed 09:00", "2016-08-13 Sat 22:50", "2016-08-03", "2016-08-03 9:00", "2016-08-03 Wed 9:00"]
      #Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*(?<interval>\+([\d][\w]))?/, x) } end)
      date_format_regexp  = ~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<hour_end>[\d]{1,2}):(?<minute_end>[\d]{2}))?\s*(?<repeat_interval>\+([\d][\w]))?/

      r = Regex.named_captures( date_format_regexp, date)

      # Set hour/minute to 0 if not exist
      r = r
      |> Map.update("hour", 0, fn(v) -> if v == "", do: "0", else: v end)
      |> Map.update("minute", 0, fn(v) -> if v == "", do: "0", else: v end)
      |> Map.update("hour_end", 0, fn(v) -> if v == "", do: "0", else: v end)
      |> Map.update("minute_end", 0, fn(v) -> if v == "", do: "0", else: v end)

      # have to convert this to integers for the Timex function
      d = Map.take(r, ["day", "month", "year", "hour", "minute", "hour_end", "minute_end"]) |> Enum.map(fn({k,v}) ->
        {k, String.to_integer(v)}
      end) |> Enum.into(%{})

      # {{year, month, day}, {hour, min, sec}}
      start_t_tuple = {{ d["year"], d["month"], d["day"] } , { d["hour"], d["minute"], 0}}
      end_t_tuple = {{ d["year"], d["month"], d["day"] } , { d["hour_end"], d["minute_end"], 0}}
      start_t = Timex.to_datetime(start_t_tuple)
      end_t = Timex.to_datetime(end_t_tuple)

      seconds_diff = Timex.diff(end_t, start_t, :seconds)
      #duration  = Timex.Duration.from_seconds(seconds_diff)
      #Timex.add(start_t, duration) == end_t
      { Timex.to_naive_datetime(start_t), seconds_diff, r["interval"] }
    end
    f_capture_date.(date)
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
      # closed and deadline can be turned directly into Ecto.DateTime
      # scheduled will need to be split into scheduled (datetime), scheduled_end (datetime), and scheduled_interval (string)
      # http://orgmode.org/manual/Timestamps.html#Timestamps
      # the repeat scheduling over multiple days doesn't actually work in org-mode
      # CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00+1w>--<2016-06-02 9:00-17:00> DEADLINE: <bla>
      # schedule can have a range of dates and also a range of times
      # TODO - for tag-based calendar scheduling, need a range of intervals. 
      # TODO - same problem will occur for bin-packing later, but let's get the rough work done first - single date
      Regex.named_captures(~r/(?<keyword>(DEADLINE|SCHEDULED|CLOSED)):/, line) ->
        r = (Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<closed>[^>\]]+)([\]>]))/, line) || %{} )
        r = (Regex.named_captures(~r/(DEADLINE:\s*([\[<])(?<deadline>[^>\]]+)([\]>]))/, line) || %{}) |> Map.merge(r)
        r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled_start>[^>\]]+)([\]>])((--)([\[<])(?<scheduled_end>[^>(CLOSED|DEADLINE)\]]+)([\]>]))?)/, line) || %{})  |> Map.merge(r)

        { scheduled_start, scheduled_start_duration,
          scheduled_repeat_interval 
        } = case Map.get(r, "scheduled_start") do
              nil -> { nil, 0, 0 }
              x -> helper_f_capture_date(x)
            end
#        { scheduled_end, scheduled_end_duration,
#          _
#        } = case Map.get(r, "scheduled_end") do
#              nil -> { nil, 0, 0 }
#              x -> helper_f_capture_date(x)
#            end
        deadline = case Map.get(r, "deadline") do
                     nil -> nil
                     x -> helper_f_capture_date(x) |> elem(0)
                   end
        closed = case Map.get(r, "closed") do
                   nil -> nil
                   x -> helper_f_capture_date(x) |> elem(0)
                 end

        %Planning{line: line, lnb: lnb, scheduled: scheduled_start, scheduled_duration: scheduled_start_duration, deadline: deadline, closed: closed}

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
