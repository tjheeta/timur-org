defmodule Ttl.ParseTest do
  use Ttl.DataCase

  alias Ttl.Parse

  describe "headline" do
    alias Ttl.Parse

    test "headline-state/title/tags" do
      assert Parse.typeof("* TODO whatever cd bla :bla:bla:bla:") == 
        %{"priority" => "", "stars" => "*", "state" => "TODO",
              "tags" => ":bla:bla:bla:", "title" => "whatever cd bla"}
    end
    test "headline-state/priority/title/tags" do
      assert Parse.typeof("* TODO [#A] whatever cd bla :1:2:3:") == 
        %{"priority" => "[#A]", "stars" => "*", "state" => "TODO",
              "tags" => ":1:2:3:", "title" => "whatever cd bla"}
    end
    test "headline-priority/title/tags" do
      assert Parse.typeof("* [#A] whatever cd bla :1:2:3:") == 
        %{"priority" => "[#A]", "stars" => "*", "state" => "",
              "tags" => ":1:2:3:", "title" => "whatever cd bla"}
    end
    test "headline-state/title/tags 2" do
      assert Parse.typeof("* TODO whatever cd bla :1:2:3:") == 
        %{"priority" => "", "stars" => "*", "state" => "TODO",
              "tags" => ":1:2:3:", "title" => "whatever cd bla"}
    end
    test "headline-title/tags" do
      assert Parse.typeof("* whatever cd bla :1:2:3:") == 
        %{"priority" => "", "stars" => "*", "state" => "",
              "tags" => ":1:2:3:", "title" => "whatever cd bla"}
    end
    test "headline-title/tags 2" do
      assert Parse.typeof("*  whatever cd bla    :1:2:3:") == 
        %{"priority" => "", "stars" => "*", "state" => "",
              "tags" => ":1:2:3:", "title" => "whatever cd bla"}
    end
    test "headline-title spaces" do
      assert Parse.typeof("*  whatever cd bla    ") == 
        %{"priority" => "", "stars" => "*", "state" => "",
              "tags" => "", "title" => "whatever cd bla"}
    end
    test "headline-title" do
      assert Parse.typeof("*  whatever cd bla") == 
        %{"priority" => "", "stars" => "*", "state" => "",
              "tags" => "", "title" => "whatever cd bla"}
    end
    test "headline-state/title" do
      assert Parse.typeof("* DONE whatever cd bla") == 
        %{"priority" => "", "stars" => "*", "state" => "DONE",
              "tags" => "", "title" => "whatever cd bla"}
    end
    test "headline-priority/title" do
      assert Parse.typeof("* [#B] whatever cd bla") == 
        %{"priority" => "[#B]", "stars" => "*", "state" => "",
              "tags" => "", "title" => "whatever cd bla"}
    end

  end
end
