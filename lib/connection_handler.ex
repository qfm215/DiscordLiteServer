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

    def handle_info(:start_accepting, state) do
        {:ok, client_pid} = ClientServer.start_link(state.current_port, state.listen_socket)
        send(self(), :start_accepting)
        GenServer.cast(ChannelServer, {:add_client, client_pid})
        {:noreply, %{state | current_port: state.current_port + 1}}
    end
end