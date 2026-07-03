defmodule ElNino.SongQueue do
  use Agent

  @doc """
  Starts the queue process and registers it under the module name.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> Qex.new() end, name: __MODULE__)
  end

  @doc """
  Pushes a URL onto the end of the queue.
  """
  def push(url) do
    Agent.update(__MODULE__, fn queue -> Qex.push(queue, url) end)
  end

  @doc """
  Pops a URL from the front of the queue. Returns `nil` if the queue is empty.
  """
  def pop() do
    Agent.get_and_update(__MODULE__, fn queue ->
      case Qex.pop(queue) do
        {{:value, value}, new_queue} -> {value, new_queue}
        {:empty, _} -> {nil, queue}
      end
    end)
  end
end
