defmodule Ttl.Parse.Elements do
  defmodule Blank,              do: defstruct lnb: 0, line: "", content: "", inside_code: false
  defmodule Heading,            do: defstruct lnb: 0, line: "", level: 1, content: "", pri: "", state: "", tags: []
  defmodule Planning,           do: defstruct lnb: 0, line: "", level: 1, content: "", closed: nil, deadline: nil, scheduled: nil, scheduled_repeat_interval: nil, scheduled_date_range: nil, scheduled_time_interval: nil 
  defmodule PropertyDrawer,     do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule LogbookDrawer,      do: defstruct lnb: 0, line: "", level: 1, content: []
  defmodule Section ,           do: defstruct lnb: 0, line: "", level: 1, content: ""
  defmodule End,                do: defstruct lnb: 0, line: "", level: 1, key: "", value: ""
  defmodule Unknown,            do: defstruct lnb: 0, line: "", level: 1, content: "", parent: ""

  @spec helper_f_capture_date(string) :: {NaiveDateTime,  integer, string }
  def helper_f_capture_date(date) do
    # To cast to Ecto.Datetime, the hour/minute needs to be non-zero
    f_capture_date = fn(date) ->
      # The following regexp correctly parses all of the below
      #dates = ["2016-06-01 Wed 9:30-17:00 +1w", "2016-06-01 Wed 9:30-17:00", "2016-06-01 Wed 9:00", "2016-06-01 Wed 09:00", "2016-08-13 Sat 22:50", "2016-08-03", "2016-08-03 9:00", "2016-08-03 Wed 9:00"]
      #Enum.map(dates, fn(x) -> { x, Regex.named_captures(~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<scheduled_hour_end>[\d]{1,2}):(?<scheduled_minute_end>[\d]{2}))?\s*(?<interval>\+([\d][\w]))?/, x) } end)
      date_format_regexp  = ~r/^(?<year>[\d]{4})-(?<month>[\d]{2})-(?<day>[\d]{2})\s*(?<dayofweek>[a-zA-Z]{3})?\s*((?<hour>[\d]{1,2}):(?<minute>[\d]{2}))?(-(?<hour_end>[\d]{1,2}):(?<minute_end>[\d]{2}))?\s*(?<repeat_interval>(\.)?\+([\d][\w]))?/

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
      # there is no end date - less than 0 
      seconds_diff = if seconds_diff < 0 do
        seconds_diff = 0
      else
        seconds_diff
      end

      #duration  = Timex.Duration.from_seconds(seconds_diff)
      #Timex.add(start_t, duration) == end_t
      { Timex.to_naive_datetime(start_t), seconds_diff, r["repeat_interval"] }
    end
    f_capture_date.(date)
  end

  # TODO - There is probably a way to capture all three planning at once
  # closed and deadline can be turned directly into Ecto.DateTime
  # scheduled will need to be split into scheduled (datetime), scheduled_end (datetime), and scheduled_interval (string)
  # http://orgmode.org/manual/Timestamps.html#Timestamps
  # the repeat scheduling over multiple days doesn't actually work in org-mode
  # CLOSED: [2016-06-02 Thu 21:22] SCHEDULED: <2016-06-01 Wed 9:00-17:00+1w>--<2016-06-02 9:00-17:00> DEADLINE: <bla>
  # schedule can have a range of dates and also a range of times
  # TODO - for tag-based calendar scheduling, need a range of intervals.
  # TODO - same problem will occur for bin-packing later, but let's get the rough work done first - single date
  defp parse_planning_line(line, lnb) do
    r = (Regex.named_captures(~r/(CLOSED:\s*([\[<])(?<closed>[^>\]]+)([\]>]))/, line) || %{} )
    r = (Regex.named_captures(~r/(DEADLINE:\s*([\[<])(?<deadline>[^>\]]+)([\]>]))/, line) || %{}) |> Map.merge(r)
    r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled_start>[^>\]]+)([\]>])((--)([\[<])(?<scheduled_end>[^>\]]+)([\]>]))?)/, line) || %{})  |> Map.merge(r)

    { scheduled_start, scheduled_time_interval, scheduled_repeat_interval} = case Map.get(r, "scheduled_start") do
                                                                               nil -> { nil, 0, "" }
                                                                               x -> helper_f_capture_date(x)
                                                                             end
    scheduled_date_range = case Map.get(r, "scheduled_end") do
                             nil -> 0
                             "" -> 0
                             x ->
                               {tmp_end, _, _ } = helper_f_capture_date(x)
                               Timex.diff(tmp_end, scheduled_start, :days)
                           end
    deadline = case Map.get(r, "deadline") do
                 nil -> nil
                 x -> helper_f_capture_date(x) |> elem(0)
               end
    closed = case Map.get(r, "closed") do
               nil -> nil
               x -> helper_f_capture_date(x) |> elem(0)
             end

    %Planning{line: line, lnb: lnb,
              scheduled: scheduled_start,
              scheduled_repeat_interval: scheduled_repeat_interval,
              scheduled_date_range: scheduled_date_range,
              scheduled_time_interval: scheduled_time_interval,
              deadline: deadline,
              closed: closed}
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

      Regex.named_captures(~r/(?<keyword>(DEADLINE|SCHEDULED|CLOSED)):/, line) ->
        %Planning{line: line, lnb: lnb}

      line =~ ~r/^:PROPERTIES:/ ->
        %PropertyDrawer{line: line, lnb: lnb}

#      line =~ ~r/^:LOGBOOK:/ ->
#        %LogbookDrawer{line: line, lnb: lnb}

      line =~ ~r/^:END:/ ->
        %End{line: line, lnb: lnb}

      true -> 
        %Unknown{line: line, lnb: lnb}
    end
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
    s_plan = parse_planning_line(s_plan.line, s_plan.lnb)
    slurp_until(t, &(&1.line =~ ~r/:END:/), &(&1 <> &2), true,  s_prop, [s_plan, s_head | ast ])
  end

  def create_elements([%Heading{} = s_head, %Planning{} = s_plan | t], ast) do
    s_plan = parse_planning_line(s_plan.line, s_plan.lnb)
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

end
