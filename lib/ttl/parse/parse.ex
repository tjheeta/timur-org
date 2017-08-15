defmodule Ttl.Parse do
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
    defstruct level: 1, title: "", content: "", closed: nil, scheduled: nil, deadline: nil, state: "", pri: "", version: 1, defer_count: 0, min_time_needed: 5, time_spent: 0, permissions: 0, tags: "", subobjects: []
  end
  defmodule Document do
    defstruct name: "", objects: []
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

      # If the list of objects is empty, and it's not a header, add it to the list
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
        r = (Regex.named_captures(~r/(SCHEDULED:\s*([\[<])(?<scheduled>[^>\]]+)([\]>]))/, line) || %{}) |> Map.merge(r)

        %Planning{line: line, lnb: lnb, scheduled: Map.get(r, "scheduled"), deadline: Map.get(r, "deadline"), closed: Map.get(r, "closed")}

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
