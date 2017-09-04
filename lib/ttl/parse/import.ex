defmodule Ttl.Parse.Import do
  # TODO - @timestamps_opts [type: :utc_datetime]
  # TODO - user timezones
  alias Ttl.Parse.Document

  def f_maybe_add_version(somemap) do
    case Map.get(somemap, :version) do
      nil ->
        version = DateTime.utc_now |> DateTime.to_unix
        Map.put(somemap, :version, version)
      _ -> somemap
    end
  end

  #  attrs = %{:kinto_token => "1e557863-6731-452b-9dde-aa30da3c7bc4"
  #            :mode => "default" | "force"
  def import(file, attrs \\ %{mode: "default"}) do
    case Application.get_env(:ttl, :storage) do
      [backend: :kinto] -> import_file(:kinto, file, attrs)
      _ -> import_file(:db, file, attrs)
    end
  end

  def import_file(backend, file, attrs \\ %{mode: "default"})

  # modes are default, force
  @spec import_file(String.t, map) :: {:ok, %Ttl.Parse.Document{}, [%Ttl.Parse.Object{}]}
  def import_file(:db, file, attrs) do
    # helper functions
    f_maybe_add_id = fn(somemap) ->
      case Map.get(somemap, :id) do
        nil ->
          {:ok, id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
          Map.put(somemap, :id, id)
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
    parsed_doc = Ttl.Parse.Consolidate.parse_file(file)
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
      |> f_maybe_add_version()
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


  # verify we have a kinto token to write into the db
  def import_file(:kinto, file, attrs) do
    case Map.get(attrs, :kinto_token) do
      nil -> {:error, "no kinto token"}
      x -> import_file_kinto(file, attrs)
    end
  end

  def f_to_struct(attrs, kind) do
    struct = struct(kind)
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end

  ### Versioning notes
  # Can't use Kinto sync unless we write ourselves a Kinto -> org adapter.
  #- current_object has no version or id -> it has not been stored
  #  - stored_object doesn't exist. Perfect
  #  - can't compare even if it identical
  #- current_object has version AND id
  #  - stored_object exists and is == version. Perfect
  #  - stored_object exists and is < version. We aren't incrementing versions, so not possible.
  #    And we want to make sure we are updating the correct version. After update accepted, then increment?
  #  - stored_object exists and is > version - what to do?
  #    - force_update - client wins
  #    - fail the object in particular, return the stored state
  #    - server wins
  #    - merge the changes - not building this right now - org-mode doesn't support crdt anyway

  # On the text editor side, we aren't updating versions.
  # On the mobile side - we could?
  # kinto uses last_modified timestamp to sync to dbs
  # the version number is the equivalent of last modified but outside of kinto
  # This means if the version ondisk == db -> good
  def f_compare_object_versions(parsed_objects, document_id, kinto_token) do

    f_compare_helper = fn(x, y) ->
      #IO.inspect "HERE"
      #IO.inspect Map.keys(x)
      #IO.inspect "DONE"
      Enum.reduce_while(x, true, fn({x_k, x_v}, acc) ->
        #IO.inspect x_k
        #IO.inspect x_v

        case Map.fetch(y, Atom.to_string(x_k)) do
          {:ok, y_v} ->
            if x_v == y_v do
              {:cont, true}
            else
              IO.inspect "HALTING"
              IO.inspect x_v
              IO.inspect y_v
              {:halt, false}
            end
          :error -> {:halt, false}
        end
      end)
    end

    db_objects = Ttl.Things.kinto_get_versions_of_objects(kinto_token, document_id)
    db_objects = Enum.map(db_objects["data"], fn(x) ->
      #{Map.get(x, "id"), Map.get(x, "last_modified") }
      {Map.get(x, "id"), Map.get(x, "version") }
    end) |> Enum.into(%{})


    {objects_to_update, objects_with_conflict} = Enum.split_with(parsed_objects, fn(x) ->
      id = x.id
      #IO.inspect "x=#{x.version}, objversion=#{db_objects[id]}"
      cond do
        db_objects[id] == nil -> true
        x.version == db_objects[id] -> true
        true -> false
      end
    end)
    # if we don't check which objects are changed and upload them all, kinto will resync the full db
    # almost guaranteeing conflicts in this case if forget to sync
    # no way to know what objects have been modified locally yet
    # doing this the super-expensive way for now - kinto slow to fetch

    db_objects = Ttl.Things.kinto_get_objects_by_document_id(kinto_token, document_id)["data"]
    |> Enum.reduce(%{}, fn(x, acc) ->
      #item = f_to_struct(x, Ttl.Parse.Object) |> Map.from_struct
      #Map.merge(acc, %{x["id"] => item })
      Map.merge(acc, %{x["id"] => x})
    end)

#p = %{closed: nil, content: "\n", deadline: nil, defer_count: 0, document_id: "23ca609d-f5f7-4cd6-8743-5da9aaa9259a", id: "424ba29b-fc23-4060-81d2-4c998c32d175", level: 1, min_time_needed: 5, permissions: 0, priority: "", properties: %{}, scheduled: nil, scheduled_date_range: nil, scheduled_repeat_interval: nil, scheduled_time_interval: nil, state: "", subobjects: [], tags: "", time_spent: 0, title: "Ttl", version: "1504545916"}

#d = %Ttl.Things.Object{ blob: nil, closed: nil, content: "\n", deadline: nil, defer_count: 0, document_id: "23ca609d-f5f7-4cd6-8743-5da9aaa9259a", id: "424ba29b-fc23-4060-81d2-4c998c32d175", inserted_at: nil, level: 1, min_time_needed: 5, path: nil, permissions: 0, priority: "", properties: %{}, scheduled: nil, scheduled_date_range: nil, scheduled_repeat_interval: nil, scheduled_time_interval: nil, state: "", tags: "", time_left: nil, time_spent: 0, title: "Ttl", updated_at: nil, version: "1504545916"}
#                       d == p 
    {objects_to_update, objects_no_change} = Enum.split_with(parsed_objects, fn(x) ->
      id = x.id

      # IO.inspect x
      # IO.inspect db_objects[id]
      # IO.inspect x == db_objects[id]
      # IO.inspect f_compare_helper.(x, db_objects[id])
      # IO.inspect "BEFORE RAISE"
      # raise "oops"
      cond do
        db_objects[id] == nil -> true
        f_compare_helper.(x, db_objects[id]) -> true
        true -> false
      end
    end)
    {objects_to_update, objects_no_change, objects_with_conflict}
  end

  @spec import_file_kinto(String.t, map) :: {:ok, %Ttl.Things.Document{}, [%Ttl.Parse.Object{}]}
  def import_file_kinto(file, attrs \\ %{mode: "default"}) do
    # helper functions
    f_maybe_add_id = fn(somemap) ->
      case Map.get(somemap, :id) do
        nil ->
          {:ok, id} = Ecto.UUID.bingenerate() |> Ecto.UUID.load
          Map.put(somemap, :id, id)
        _ -> somemap
      end
    end


    # parsed_doc = Ttl.Parse.parse("/home/tjheeta/org/notes.org")

    kinto_token = Map.get(attrs, :kinto_token)
    # Can't use the file name as the indicator as the thing could move around on fs
    parsed_doc = Ttl.Parse.Consolidate.parse_file(file)
    |> f_maybe_add_id.()

    # http GET "http://localhost:8888/v1/buckets/default/collections/documents/records/someid" --auth kinto_token:de4927d9-a099-4ec8-bb99-4f69888acb34
    # Need a document_id generated to add to the objects
    #%{"id" => "4adf2ecf-e474-4170-90af-e355e4aafb84",
    #  "last_modified" => 1504375579672, "metadata" => %{},
    #  "name" => "/home/tjheeta/repos/self/ttl/README.org"}
    db_doc = case Ttl.Things.kinto_get_document!(kinto_token, parsed_doc.id) do
               nil ->
                 data = Map.from_struct(parsed_doc) |> Map.take([:id, :name, :metadata])
                 tmpdoc = %Ttl.Things.Document{id: parsed_doc.id}
                 res = Ttl.Things.kinto_create_document(kinto_token, data)
                 f_to_struct(res["data"], Ttl.Things.Document)
                 #res["data"]
               res ->
                 res["data"]
                 |> f_to_struct(Ttl.Things.Document)
             end

    # Add versions and document_id to the parsed objects
    parsed_objects = Enum.map(parsed_doc.objects, fn(x) ->
      Map.from_struct(x)
      |> Map.put_new(:document_id, db_doc.id)
      |> f_maybe_add_id.()
      |> Ttl.Parse.Import.f_maybe_add_version()
    end)


    {objects_to_update, objects_no_change, objects_with_conflict} = cond do
      attrs.mode == "force" -> {parsed_objects, []}
      true -> f_compare_object_versions(parsed_objects, db_doc.id, kinto_token)
    end

    ordered_object_ids = Enum.map(parsed_objects, &(Map.get(&1, :id)) )
    # TODO - kinto can batch these together
    db_doc = Ttl.Things.kinto_update_document(kinto_token, db_doc, %{objects: ordered_object_ids} )["data"] |> f_to_struct(Ttl.Things.Document)
    # this will replace the objects with what is on disk, not patch
    Ttl.Things.kinto_create_or_update_objects(kinto_token, objects_to_update)
    # TODO - find out which objects did not update and return conflicts
    IO.inspect "update = #{length(objects_to_update)}, nochange = #{length(objects_no_change)}, conflict = #{length(objects_with_conflict)}"
    {:ok, db_doc, objects_with_conflict}
  end

end

