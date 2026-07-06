defmodule ElNino.SongQueue do
  use Agent, restart: :transient

  alias ElNino.Common

  @doc """
  Starts the queue process and registers it under the module name.
  """
  def start_link([guild_id]) do
    Agent.start_link(fn -> Qex.new() end, name: Common.via_guild_queue_registry(guild_id))
  end

  @doc """
  Pushes a URL onto the end of the queue.
  """
  def push(url, guild_id) do
    Agent.update(Common.via_guild_queue_registry(guild_id), fn queue -> Qex.push(queue, url) end)
  end

  @doc """
  Pops a URL from the front of the queue. Returns `nil` if the queue is empty.
  """
  def pop(guild_id) do
    Agent.get_and_update(Common.via_guild_queue_registry(guild_id), fn queue ->
      case Qex.pop(queue) do
        {{:value, value}, new_queue} -> {value, new_queue}
        {:empty, _} -> {nil, queue}
      end
    end)
  end

  def clear(guild_id) do
    Agent.update(Common.via_guild_queue_registry(guild_id), fn _queue -> Qex.new() end)
  end
end
