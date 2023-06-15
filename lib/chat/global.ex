defmodule Chat.Global do
  use GenServer

  def start() do
    GenServer.start(__MODULE__, %{}, name: :global)
  end

  def init(_) do
    {:ok, %{users: [], rooms: [], chats: []}}
  end

  def create_user(user_name, pid) do
    GenServer.cast(:global, {:create_user, user_name, pid})
  end

  def create_room(room_name) do
    GenServer.cast(:global, {:create_room, room_name})
  end

  def create_chat(chat_name) do
    GenServer.call(:global, {:create_chat, chat_name})
  end

  def get_rooms() do
    GenServer.call(:global, :get_rooms)
  end

  def send_user_events(user_room, user_name, room_name) do
    user= get_user(user_name, room_name)
    send(user.pid, {:user_chat, user_room})
  end

  def get_user(user_name, room_name) do
    Chat.Room.get_room(room_name).users
    |> Enum.find(fn user -> user.user_name == user_name end)
  end

  def send_events(event, values, users) do
    for user <- users do
      send(user.pid, {:new_room, values.rooms})
    end
  end

  @impl true
  def handle_call(:get_rooms, _from, state) do
    {:reply, state.rooms, state}
  end

  @impl true
  def handle_cast({:create_user, user_name, pid}, state) do
    case Enum.find(state.users, fn user -> user.user_name == user_name end) do
      nil ->
        user = state.users ++ [%{user_name: user_name, pid: pid}]
        users = %{state | users: user}
        {:noreply, users}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:create_room, room_name}, state) do
    case Enum.find(state.rooms, fn room -> room.room_name == room_name end) do
      nil ->
        {:ok, pid} = Chat.Room.start(room_name)
        room = state.rooms ++ [%{room_name: room_name, pid: pid}]
        rooms = %{state | rooms: room}
        send_events(:new_room, rooms, state.users)
        {:noreply, rooms}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:create_chat, chat_name}, _from, state) do
    {user_name1, user_name2} = chat_name

    case Enum.find(state.chats, fn chat ->
           chat.chat_name == chat_name or chat.chat_name == {user_name2, user_name1}
         end) do
      nil ->
        case Chat.Room.start(chat_name) do
          {:ok, pid} ->
            chat = state.chats ++ [%{chat_name: chat_name, pid: pid}]
            chats = %{state | chats: chat}
            {:reply, chats, chats}

          {:error, _} ->
            {:reply, state, state}

          _ ->
            {:reply, state, state}
        end

      value ->
        {:reply, {:ok, value.chat_name}, state}
    end
  end
end
