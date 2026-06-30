defmodule ElNinoTest do
  use ExUnit.Case
  doctest ElNino

  test "greets the world" do
    assert ElNino.hello() == :world
  end
end
