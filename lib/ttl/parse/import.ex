defmodule Ttl.Parse.Import do
  # TODO - @timestamps_opts [type: :utc_datetime]
  # TODO - user timezones
  alias Ttl.Parse.Document

  # modes are default, force
  @spec import_file(String.t, map) :: {:ok, %Ttl.Parse.Document{}, [%Ttl.Parse.Object{}]}
  def import_file(file, attrs \\ %{mode: "default"}) do
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

end
