defmodule ChatWeb.Roomlive do
  use Phoenix.LiveView, layout: {ChatWeb.LayoutView, "live.html"}
  use Phoenix.HTML
  alias Chat.Global
  alias Chat.Room

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       user_name: "",
       users: [],
       messages: [],
       room_name: ""
     )}
  end

  @impl true
  def handle_params(%{"user_name" => user_name, "room_name" => room_name}, _, socket) do
    Room.update_user(%{pid: self(), user_name: user_name}, room_name)
    room = Room.get_room(room_name) || %{users: [], messages: []}

    {:noreply,
     socket
     |> assign(:user_name, user_name)
     |> assign(:users, Enum.map(room.users, & &1.user_name))
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

  def handle_event("click_move", message_params, socket) do
    Global.send_user_events(
      socket.assigns.user_name,
      Map.get(message_params, "item"),
      socket.assigns.room_name
    )

    {:noreply, socket}
  end

  def handle_info({:new_message, room}, socket) do
    {:noreply,
     socket
     |> assign(:messages, Enum.reverse(room.messages))}
  end

  def handle_info({:new_user, users}, socket) do
    {:noreply,
     socket
     |> assign(:users, users)}
  end

  def handle_info({:user_chat, user}, socket) do
    socket =
      socket
      |> put_flash(
        :info,
        [
          "Please, visit ",
          link("User Chat",
            to:
              "http://localhost:4000/chat?user_name=" <>
                socket.assigns.user_name <> "&user_name2=" <> user
          ),
          "!"
        ]
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Room <%= @room_name%> --- User <%= @user_name%></h1>

      <h2> Messages</h2>
      <%= for item <- @messages do %>
        <h3>
        <%= item.user_name %> : <%= item.message %>
        </h3>
      <% end %>
      <h2>Users</h2>
      <%= for item <- @users do %>
        <h3 phx-click="click_move" phx-value-item={item}>
         <a href={"/chat?user_name=" <> assigns.user_name <> "&user_name2=" <> item}><%= item %></a>
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
