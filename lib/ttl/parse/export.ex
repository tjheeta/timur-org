defmodule Ttl.Parse.Export do

  defp db_date_to_string(date, bracket, time_interval, date_range, repeat_interval ) do

    date = case Application.get_env(:ttl, :storage) do
             [backend: :kinto] ->
               naive = Timex.parse!(date, "{ISO:Extended}")
               { {naive.year, naive.month, naive.day}, {naive.hour, naive.minute, naive.second} }
             _ ->
               # remove the last tuple
               { ymd, {h, m, s, _}} = date
               { ymd, {h, m, s}}
           end

    # TODO - the second date
    # The hours will remain the same since we don't have enough information for that
    # org-mode scheduling is also a bit weird on this in the planning header, so keep it simple
    date1_str = db_date_to_string_helper(date, bracket, time_interval, repeat_interval)

    date2_str = if date_range > 0 do

      duration  = Timex.Duration.from_days(date_range)
      date2 = Timex.to_datetime(date) |> Timex.add(duration) |> Timex.to_erl
      "--" <> db_date_to_string_helper(date2, bracket, time_interval, "")
    else
        ""
    end
    date1_str <> date2_str

  end
  defp db_date_to_string_helper(date, bracket, time_interval, repeat_interval ) do
    # TODO - this entire nonsense could have been avoided if I just put in unixtime 
    # Kinto stores as text as naive datetime. Ecto and postgres something else

    { ymd, {h, m, s}} = date

    date_str =
      case {h, m, s, time_interval} do
        {0,0,0,0} ->
          Timex.format!(date, "%Y-%m-%d %a #{repeat_interval}", :strftime)
        #{0,0,0,_} ->
        #  # having a time interval and no start time makes no sense
        #  duration  = Timex.Duration.from_seconds(time_interval)
        #  date = Timex.to_datetime(date) |> Timex.add(duration)
        #  Timex.format!(date, "%Y-%m-%d %a #{repeat_interval}", :strftime)
        {_,_,_,0} ->
          Timex.format!(date, "%Y-%m-%d %a %H:%M #{repeat_interval}", :strftime)
        _ ->
          duration  = Timex.Duration.from_seconds(time_interval)
          end_date = Timex.to_datetime(date) |> Timex.add(duration)
          end_time = Timex.format!(end_date, "%H:%M", :strftime)
          Timex.format!(date, "%Y-%m-%d %a %H:%M-#{end_time} #{repeat_interval}", :strftime)
      end |> String.trim_trailing

    case bracket do
      "[" -> "[" <> date_str <> "]"
      "]" -> "[" <> date_str <> "]"
      "[]" -> "[" <> date_str <> "]"
      :square -> "[" <> date_str <> "]"
      _ -> "<" <> date_str <> ">"
    end
  end

  # probably quite a few faster and better ways to do this in the db
  # but not caring about performance quite yet
  # ttl_dev=# with x (id_list) as (select objects from things_documents) select o.id, o.title from things_objects o, x where id = any (x.id_list) order by array_position(x.id_list, o.id  );
  defp query_db(document_id) do
    import Ecto.Query
    q_struct = from o in "things_objects",
      where: o.document_id == ^document_id,
      select: %{fragment("cast(id as text)") =>
        [ fragment("cast(id as text)"), o.level, o.title, o.state, o.priority, o.content, o.properties,
          o.scheduled, o.scheduled_date_range, o.scheduled_repeat_interval, o.scheduled_time_interval,
          o.closed, o.deadline, o.version, o.tags ]
      }
    #q_map = from o in "things_objects",
    #  where: o.document_id == ^document_id,
    #  select: %{fragment("cast(id as text)") =>
    #    %{level: o.level, title: o.title, content: o.content, properties: o.properties,
    #      scheduled: o.scheduled, closed: o.closed, deadline: o.deadline}}
    #q_all = from o in Ttl.Things.Object, 
    #where: o.document_id == ^document_id
    Ttl.Repo.all(q_struct)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.merge(acc, x) end)
  end

  def empty?(x) do
    x == nil || x == ""
  end

  def object_to_string(data, add_id \\ true) do
    # deconstruct the query based on where it has come from
    [ id, level, title, state, priority, content, properties,
      scheduled, scheduled_date_range, scheduled_repeat_interval, scheduled_time_interval,
      closed, deadline, version, tags ] =
      case Application.get_env(:ttl, :storage) do
        [backend: :kinto] ->
          [ data["id"], data["level"], data["title"], data["state"], data["priority"], data["content"], data["properties"],
            data["scheduled"], data["scheduled_date_range"], data["scheduled_repeat_interval"], data["scheduled_time_interval"],
            data["closed"], data["deadline"], data["version"], data["tags"] ]
        _ -> data
      end

    acc = ""
    str_level = String.duplicate("*", level)
    acc = if level > 0, do: acc <> str_level <> " ", else: acc
    acc = if !empty?(state), do: acc <> state <> " ", else: acc
    acc = if !empty?(priority), do: acc <> priority <> " ", else: acc
    acc = if !empty?(title), do: acc <> title <> " ", else: acc
    acc = if !empty?(tags), do: acc <> tags <> " ", else: acc
    acc = (if String.length(acc) > 5, do: String.trim_trailing(acc, " ") <> "\n", else: acc)

    planning_string = ""
    planning_string = planning_string <> if closed,  do: " CLOSED: " <>
      db_date_to_string(closed, :square, 0, 0, ""), else: ""
    planning_string = planning_string <> if scheduled,  do: " SCHEDULED: " <>
      db_date_to_string(scheduled, :notsquare, scheduled_time_interval, scheduled_date_range, scheduled_repeat_interval), else: ""
    planning_string = planning_string <> if deadline,  do: " DEADLINE: " <>
      db_date_to_string(deadline, :notsquare, 0, 0, ""), else: ""
    planning_string = planning_string <> (if String.length(planning_string) > 5, do: "\n", else: "")

    # strip starting/any double spaces
    planning_string = planning_string |> String.trim_leading |> String.replace("  ", " ") 

    acc = acc <> planning_string

    property_string = case add_id do
      true ->  "PREFIX_OBJ_ID: #{id}\n:PREFIX_OBJ_VERSION: #{version}\n"
      false -> ""
    end

    property_string =
    if properties && length(Map.keys(properties)) > 0 do
      tmpstr = Enum.reduce(properties, property_string, fn({k,v}, acc) ->
        str = ":#{k}:    #{v}\n"
        acc <> str
      end) 
      ":PROPERTIES:\n#{tmpstr}:END:\n"
    else
      property_string
    end
    acc = acc <> property_string

    if content, do: acc <> content, else: acc
  end

  def generate_metadata(document, add_id \\ true) do
    [doc_id, metadata] =
      case Application.get_env(:ttl, :storage) do
        [backend: :kinto] -> [document["id"], document["metadata"] ]
                 _ -> [document.id, document.metadata]
      end

    acc = if add_id do
      "#+PREFIX_DOC_ID:#{doc_id}\n"
    else
      ""
    end

    acc = Enum.reduce( metadata, acc, fn({k,v}, acc) ->
      str = "#+#{k}: #{v}"
      if String.length(str) do
        acc <> str <> "\n"
      else
        acc
      end
    end)
    acc = if String.length(acc) > 0, do: acc <> "\n", else: acc # adding a newline
  end

  # attrs = %{:kinto_token => conn.private[:kinto_token], :add_id => true}
  def export_file(filename, string_uuid, attrs \\ %{add_id: true}) do
    str = export(string_uuid, attrs)
    File.write(filename, str)
  end

  # attrs = %{:kinto_token => conn.private[:kinto_token], :add_id => true}
  def export(string_uuid, attrs \\ %{add_id: true}) do
    case Application.get_env(:ttl, :storage) do
      [backend: :kinto] -> export_id_to_str(:kinto, string_uuid, attrs)
      _ -> export_id_to_str(:db, string_uuid, attrs)
    end
  end

  def export_id_to_str(backend, string_uuid, attrs \\ %{add_id: true})

  def export_id_to_str(:db, string_uuid, attrs) do
    # get the data for the file
    # TODO - need to add spec format and put these functions non anon
    {:ok, binary_uuid}= Ecto.UUID.dump(string_uuid)
    document = Ttl.Things.get_document!(string_uuid)
    unsorted_data = query_db(binary_uuid)
    sorted_data = for id <- document.objects, do: unsorted_data[id]

    # now need to merge the file together
    str = generate_metadata(document, attrs[:add_id])
    Enum.reduce(sorted_data, str, fn(x, acc) ->
      acc <> object_to_string(x, attrs[:add_id])
    end)
  end

  def export_id_to_str(:kinto, string_uuid, attrs) do
    # get the data for the file
    # TODO - need to add spec format and put these functions non anon
    document = Ttl.Things.kinto_get_document!(attrs[:kinto_token], string_uuid)["data"]
    unsorted_data = Ttl.Things.kinto_get_data_of_objects(attrs[:kinto_token], string_uuid)["data"] |> Enum.reduce(%{}, fn(x, acc) ->
      Map.merge(acc, %{x["id"] => x})
    end)
    sorted_data = for id <- document["objects"], do: Map.get(unsorted_data,id)

    # now need to merge the file together
    str = generate_metadata(document, attrs[:add_id])
    Enum.reduce(sorted_data, str, fn(x, acc) ->
      acc <> Ttl.Parse.Export.object_to_string(x, attrs[:add_id])
    end)
  end

end
