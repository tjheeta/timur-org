defmodule Ttl.Web.AgendaCommander do
  use Drab.Commander
  # Place your event handlers here
  #
  # def button_clicked(socket, sender) do
  #   set_prop socket, "#output_div", innerHTML: "Clicked the button!"
  # end
  #
  # Place you callbacks here
  #
  # onload :page_loaded 
  #
  # def page_loaded(socket) do
  #   set_prop socket, "div.jumbotron h2", innerText: "This page has been drabbed"
  # end
  def uppercase(socket, sender) do
    text = sender.params["text_to_uppercase"]
    poke socket, text: String.upcase(text)
  end
  def lowercase(socket, sender) do
    text = sender.params["text_to_uppercase"]
    poke socket, text: String.downcase(text)
  end
  def delete_object(socket, sender) do
    object_id = sender.params["delete_object_id"] 
    object = %Ttl.Things.Object{id: object_id}
    Ttl.Things.delete_object(object)

    poke socket, text: "CLICKED-" <> object_id

  end
end
