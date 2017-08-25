defmodule Ttl.Parse.Object do
  defstruct id: nil, level: 1, title: "", content: "", closed: nil, scheduled: nil, scheduled_repeat_interval: nil, scheduled_date_range: nil, scheduled_time_interval: nil, deadline: nil, state: "", priority: "", version: 1, defer_count: 0, min_time_needed: 5, time_spent: 0, permissions: 0, tags: "", properties: %{}, subobjects: []
end

defmodule Ttl.Parse.Document do
  defstruct id: nil, name: "", metadata: [], objects: []
end

defmodule Ttl.Parse.Consolidate do
  alias Ttl.Parse.Document
  alias Ttl.Parse.Object

  def consolidate_objects_to_document(ast) do
    consolidate_objects_to_document(ast, %Document{})
  end

  def consolidate_objects_to_document([], doc) do
    %{ doc | objects: (Enum.reverse(doc.objects ) ) }
  end

  def consolidate_objects_to_document([h | t], doc) do
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
      h.__struct__ == Ttl.Parse.Elements.Heading ->
        obj = %Object{title: h.content, level: h.level, priority: h.pri, state: h.state, tags: h.tags}
        consolidate_objects_to_document(t, %{doc | objects: [obj | doc.objects]} )

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

        consolidate_objects_to_document(t , %{doc | objects: [h | doc.objects]})

      true ->
        # not a heading, we need to update the heading to include planning, logbook, section, or append to list
        current_object = Enum.at(doc.objects, current_object_index)
        current_object = cond do
          h.__struct__ == Ttl.Parse.Elements.Planning ->
            %{current_object |
              closed: h.closed, deadline: h.deadline, scheduled: h.scheduled,
              scheduled_repeat_interval: h.scheduled_repeat_interval,
              scheduled_date_range: h.scheduled_date_range,
              scheduled_time_interval: h.scheduled_time_interval
             }
          h.__struct__ == Ttl.Parse.Elements.Section ->
            %{current_object | content: (current_object.content <> h.content) }
          h.__struct__ == Ttl.Parse.Elements.PropertyDrawer ->
            # set the properties component and set the id/version if they exist
            %{current_object | properties: f_convert_property_drawer_to_map.(h.content) }
            |> f_maybe_set_id_from_properties_map.()
            |> f_maybe_set_version_from_properties_map.()
          h.__struct__ == Ttl.Parse.Elements.LogbookDrawer ->
            %{current_object | subobjects: [ h  | current_object.subobjects ] }
          true -> current_object
        end

        # replace the current object in the doc
        doc_objects = List.replace_at(doc.objects, current_object_index, current_object)
        consolidate_objects_to_document(t, %{doc | objects: doc_objects})
    end
  end

  def parse_file(file) do
    s = File.stream!(file,  [:read, :utf8], :line)
    data = Enum.reduce(s, [], fn(line, acc) ->
      [line | acc ]
    end)
    |> Enum.reverse
    |> parse(file)
  end

  # returns a Document - doesn't do any extraneous additions to the file - only parsing
  # expects an array of strings
  @spec parse([String.t], String.t) :: %Ttl.Parse.Document{}
  def parse(data, file) do
    #s = File.stream!("/home/tjheeta/org/notes.org",  [:read, :utf8], :line)
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

    # this builds all the individual elements from lines
    Enum.map(data, fn({line, lnb}) -> Ttl.Parse.Elements.typeof({line, lnb}) end)
    # this creates elements - planning, propertydrawer, logbookdrawer, etc.
    |> Ttl.Parse.Elements.create_elements([])
    # creates a document
    |> Ttl.Parse.Consolidate.consolidate_objects_to_document(%Document{name: file, metadata: file_metadata, id: file_metadata["PREFIX_DOC_ID"]})
  end
end