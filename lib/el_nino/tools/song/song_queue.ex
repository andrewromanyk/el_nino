defmodule ElNino.SongQueue do
  use Agent, restart: :transient

  @doc """
  Starts the queue process and registers it under the module name.
  """
  def start_link([guild_id]) do
    Agent.start_link(fn -> Qex.new() end, name: via_guild_queue_registry(guild_id))
  end

  @doc """
  Pushes a URL onto the end of the queue.
  """
  def push(url, guild_id) do
    Agent.update(via_guild_queue_registry(guild_id), fn queue -> Qex.push(queue, url) end)
  end

  @doc """
  Pushes a list of URLs onto the end of the queue.
  """
  def push_list(urls, guild_id) when is_list(urls) do
    Agent.update(via_guild_queue_registry(guild_id), fn queue ->
      Enum.reduce(urls, queue, fn url, acc -> Qex.push(acc, url) end)
    end)
  end

  @doc """
  Pops a URL from the front of the queue. Returns `nil` if the queue is empty.
  """
  def pop(guild_id) do
    Agent.get_and_update(via_guild_queue_registry(guild_id), fn queue ->
      case Qex.pop(queue) do
        {{:value, value}, new_queue} -> {value, new_queue}
        {:empty, q} -> {nil, q}
      end
    end)
  end

  def get_all(guild_id) do
    Agent.get(via_guild_queue_registry(guild_id), fn queue -> Enum.to_list(queue) end)
  end

  def clear(guild_id) do
    Agent.update(via_guild_queue_registry(guild_id), fn _queue -> Qex.new() end)
  end

  def terminate(guild_id) do
    Agent.stop(via_guild_queue_registry(guild_id))
  end

  def via_guild_queue_registry(guild_id) do
    ElNino.Common.via_registry(GuildSongQueueRegistry, guild_id)
  end
end
