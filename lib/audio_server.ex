defmodule AudioServer do
    use GenServer

    @conf Application.get_env :discord_lite_server, :network
    def start_link(port) do
        ip = @conf[:ip] || {127,0,0,1}
        GenServer.start_link(__MODULE__, [ip, port], []) # Start 'er up
    end

    def init [ip, port] do
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true, ip: ip])
      {:ok, %{socket: socket, port: port}}
    end
  
    def handle_info({:send_data, from, data}, %{client_address: client_address, client_port: client_port}=state) do
        :gen_udp.send(state.socket, client_address, client_port, <<from::little-signed-32>> <> data)
        {:noreply, state}
    end

    def handle_info({:send_data, _from, _data}, state) do
        {:noreply, state}
    end

    def handle_info({:udp, _socket, address, port, data}, state) do
        send(MainServer, {:send_everyone, state.port, data})
        if (Map.has_key?(state, :client_address)) do
            {:noreply, state}
        else
            {:noreply, state |> Map.merge(%{client_address: address, client_port: port})}
        end
    end

    def handle_info(:disconnect, state) do
        IO.inspect "udp disconnecting from #{inspect state.client_address} on port #{state.port}"
        :gen_udp.close(state.socket)
        {:stop, :normal, nil}
    end
end
#{:ok, _pid} = Supervisor.start_link([{UDPServer, 2052}], strategy: :one_for_one)