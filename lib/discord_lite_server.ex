defmodule DiscordLiteServer do
  use Application

  def start(_type, _args) do
    children = [
      {MainServer, nil},
      {ConnectionHandler, nil}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def hello do
  end
end
