defmodule ChatWeb.Chatlive do
  use Phoenix.LiveView, layout: {ChatWeb.LayoutView, "live.html"}
  use Phoenix.HTML
  alias Chat.Room
  alias Chat.Global

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       user_name: "",
       user_name2: "",
       room_name: "",
       messages: []
     )}
  end

  @impl true
  def handle_params(%{"user_name" => user_name, "user_name2" => user_name2}, _, socket) do
    room_name =
      case Global.create_chat({user_name, user_name2}) do
        {:ok, value} -> value
        _ -> {user_name, user_name2}
      end

    user = %{pid: self(), user_name: user_name}
    Room.update_create_user(user, room_name)
    room = Room.get_room(room_name) || %{users: [], messages: []}

    {:noreply,
     socket
     |> assign(:user_name, user_name)
     |> assign(:user_name2, user_name2)
     |> assign(:messages, Enum.reverse(room.messages))
     |> assign(:room_name, room_name)}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  def handle_event("create_message", message_params, socket) do
    message =
      Map.get(message_params, "user")
      |> Map.get("message")

    Room.send_message(socket.assigns.user_name, message, socket.assigns.room_name)
    {:noreply, socket}
  end

  def handle_info({:new_message_priv, room}, socket) do
    {:noreply,
     socket
     |> assign(:messages, Enum.reverse(room.messages))}
  end

  def render(assigns) do
    ~H"""
      <h1>Chat  --- User <%= @user_name%> -- to User <%= @user_name2%> </h1>

      <h2> Messages</h2>
      <%= for item <- @messages do %>
        <h3>
        <%= item.user_name %> : <%= item.message %>
        </h3>
      <% end %>

      <.form let={f} for={:user} phx-submit="create_message">
      <%= label f, :message %>
      <%= text_input f, :message%>

      <%= submit "Create message" %>
      </.form>

    """
  end
end
