defmodule ConnectionHandler do
    use GenServer

    @conf Application.get_env :discord_lite_server, :network
    def start_link _ do
        ip = @conf[:ip] || {127,0,0,1}
        port = @conf[:port] || 11000
        GenServer.start_link(__MODULE__, [ip, port], name: __MODULE__)
    end

    def init [ip, port] do
        {:ok, listen_socket}= :gen_tcp.listen(port, [:binary,{:packet, 0}, {:active, true}, {:ip, ip}, {:reuseaddr, true}])
        send(self(), :start_accepting)
        {:ok, %{listen_socket: listen_socket, current_port: port + 1}}
    end

    def start_accepting() do
        send(__MODULE__, :start_accepting)
    end

    def handle_info(:start_accepting, state) do
        spawn fn -> {:ok, client_pid} = ClientServer.start_link(state.listen_socket) end
        {:noreply, %{state | current_port: state.current_port + 1}}
    end

    def get_current_port() do
        GenServer.call(__MODULE__, :get_current_port)
    end

    def handle_call(:get_current_port, _from, state) do
        {:reply, state.current_port, state}
    end

    def reset_port() do
        GenServer.cast(__MODULE__, :reset_port)
    end

    def handle_cast(:reset_port, state) do
        IO.inspect("Resetting audio port to #{((@conf[:port] || 11000) + 1)}")
        {:noreply, %{state | current_port: ((@conf[:port] || 11000) + 1)}}
    end
end