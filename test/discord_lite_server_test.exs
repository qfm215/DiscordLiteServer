defmodule DiscordLiteServerTest do
  use ExUnit.Case
  doctest DiscordLiteServer

  test "greets the world" do
    assert DiscordLiteServer.hello() == :world
  end
end
