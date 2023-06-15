defmodule Chat.Room do
  use GenServer

  def start(name) do
    GenServer.start(__MODULE__, %{}, name: {:global, name})
  end

  def init(_) do
    {:ok, %{users: [], messages: []}}
  end

  def set_user_room(user, room_name) do
    GenServer.cast({:global, room_name}, {:set_user_room, user})
  end

  def update_user(user, room_name) do
    GenServer.cast({:global, room_name}, {:update_user, user})
  end

  def send_message(user, message, room_name) do
    GenServer.cast({:global, room_name}, {:send_message, user, message})
  end

  def update_create_user(user, room_name) do
    GenServer.cast({:global, room_name}, {:update_create_user, user})
  end

  def get_room(room_name) do
    GenServer.call({:global, room_name}, :get_room)
  end

  def send_user_events(event, messages, users) do
    for user <- users do
      send(user.pid, {event, messages})
    end
  end

  @impl true
  def handle_cast({:update_create_user, user}, state) do
    user_result =
      if Enum.empty?(state.users) do
        [user]
      else
        case Enum.find(state.users, fn user_state -> user_state == user end) do
          nil -> [user | state.users]
          user -> Map.put(user, :pid, user.pid)
        end
      end

    users = %{state | users: user_result}
    {:noreply, users}
  end

  @impl true
  def handle_cast({:set_user_room, user}, state) do
    user_name = [user | state.users]
    users = %{state | users: user_name}

    send_user_events(:new_user, users, state.users)
    {:noreply, users}
  end

  @impl true
  def handle_cast({:update_user, user}, state) do
    user_result =
      Enum.map(state.users, fn map ->
        if user.user_name == map.user_name do
          Map.put(map, :pid, user.pid)
        else
          map
        end
      end)

    users = %{state | users: user_result}
    {:noreply, users}
  end

  @impl true
  def handle_cast({:send_message, user, message}, state) do
    message_created = [%{user_name: user, message: message} | state.messages]
    messages = %{state | messages: message_created}
    send_user_events(:new_message_priv, messages, state.users)
    {:noreply, messages}
  end

  @impl true
  def handle_call(:get_room, _from, state) do
    {:reply, state, state}
  end
end
