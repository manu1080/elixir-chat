defmodule ChatWeb.Userlive do
  use Phoenix.LiveView, layout: {ChatWeb.LayoutView, "live.html"}
  use Phoenix.HTML
  alias Chat.Global
  alias Chat.Room

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Global.start()
    end

    {:ok,
     assign(socket,
       user_name: "",
       rooms: []
     )}
  end

  @impl true
  def handle_params(%{"user_name" => user_name}, _, socket) do
    rooms =
      if Process.whereis(:global) do
        Global.get_rooms()
      else
        []
      end

    {:noreply,
     socket
     |> assign(:user_name, user_name)
     |> assign(:rooms, rooms)}
  end

  @impl true
  def handle_params(_, _, socket) do
    rooms =
      if Process.whereis(:global) do
        Global.get_rooms()
      else
        []
      end

    {:noreply,
     socket
     |> assign(:rooms, rooms)}
  end

  def handle_event("create_user", user_params, socket) do
    user_name =
      Map.get(user_params, "user")
      |> Map.get("user_name")

    Global.create_user(user_name, self())

    {:noreply,
     socket
     |> assign(:user_name, user_name)}
  end

  def handle_event("create", room_params, socket) do
    room_name =
      Map.get(room_params, "room")
      |> Map.get("room_name")

    Global.create_room(room_name)
    {:noreply, socket}
  end

  def handle_event("click_room", %{"item" => item}, socket) do
    Room.set_user_room(%{user_name: socket.assigns.user_name, pid: self()}, item)
    {:noreply, socket}
  end

  def handle_info({:new_room, rooms}, socket) do
    {:noreply,
     socket
     |> assign(:rooms, rooms)}
  end

  def render(assigns) do
    ~H"""
    <h1>User <%= @user_name%></h1>

    <h1>Rooms</h1>
    <ul>
      <%= for item <- @rooms do %>
        <li phx-click="click_room" phx-value-item={item.room_name}>
          <a href={"/room?room_name=" <> item.room_name <> "&user_name=" <> assigns.user_name}><%= item.room_name %></a>
        </li>
      <% end %>
    </ul>
    <.form let={f} for={:room} phx-submit="create">
      <%= label f, :room_name %>
      <%= text_input f, :room_name %>

      <%= submit "Create room" %>
    </.form>
    <.form let={f} for={:user} phx-submit="create_user">
      <%= label f, :user_name %>
      <%= text_input f, :user_name %>

      <%= submit "Create user" %>
    </.form>
    """
  end
end
