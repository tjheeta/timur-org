defmodule Ttl.Parse.Export do

  defp db_date_to_string(date, bracket, time_interval, date_range, repeat_interval ) do
    # remove the last tuple 
    { ymd, {h, m, s, _}}  = date
    date = { ymd, {h, m, s}}

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

    # TODO - the second date 

    case bracket do
      "[" -> "[" <> date_str <> "] "
      "]" -> "[" <> date_str <> "] "
      "[]" -> "[" <> date_str <> "] "
      :square -> "[" <> date_str <> "] "
      _ -> "<" <> date_str <> "> "
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
          o.closed, o.deadline, o.version ]
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


  defp object_to_string(data, add_id \\ true) do
    # deconstruct the query
    [ id, level, title, state, priority, content, properties,
      scheduled, scheduled_date_range, scheduled_repeat_interval, scheduled_time_interval,
      closed, deadline, version ] = data
    acc = ""
    str_level = String.duplicate("*", level)
    acc = if level > 0, do: acc <> str_level <> " ", else: acc
    acc = if state, do: acc <> state <> " ", else: acc
    acc = if priority, do: acc <> priority <> " ", else: acc
    acc = if title, do: acc <> title <> " ", else: acc
    acc = (if String.length(acc) > 5, do: String.trim_trailing(acc, " ") <> "\n", else: acc)

    planning_string = ""
    planning_string = planning_string <> if closed,  do: "CLOSED: " <>
      db_date_to_string(closed, :square, 0, 0, ""), else: ""
    planning_string = planning_string <> if scheduled,  do: "SCHEDULED: " <>
      db_date_to_string(scheduled, :notsquare, scheduled_time_interval, scheduled_date_range, scheduled_repeat_interval), else: ""
    planning_string = planning_string <> if deadline,  do: "DEADLINE: " <>
      db_date_to_string(deadline, :notsquare, 0, 0, ""), else: ""
    planning_string = planning_string <> (if String.length(planning_string) > 5, do: "\n", else: "")
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

  defp generate_metadata(document, add_id \\ true) do
    acc = if add_id do
      "#+PREFIX_DOC_ID:#{document.id}\n"
    else
      ""
    end
    acc = Enum.reduce( document.metadata, acc, fn({k,v}, acc) ->
      str = "#+#{k}: #{v}"
      if String.length(str) do
        acc <> str <> "\n"
      else
        acc
      end
    end)
    acc = if String.length(acc) > 0, do: acc <> "\n", else: acc # adding a newline
  end

  def export_file(filename, string_uuid, add_id \\ true) do
    str = export(string_uuid, add_id)
    File.write(filename, str)
  end

  def export(string_uuid, add_id \\ true) do
    # get the data for the file
    # TODO - need to add spec format and put these functions non anon
    {:ok, binary_uuid}= Ecto.UUID.dump(string_uuid)
    document = Ttl.Things.get_document!(string_uuid)
    unsorted_data = query_db(binary_uuid)
    sorted_data = for id <- document.objects, do: unsorted_data[id]

    # now need to merge the file together
    str = generate_metadata(document, add_id)
    Enum.reduce(sorted_data, str, fn(x, acc) ->
      acc <> object_to_string(x, add_id)
    end)
  end
end