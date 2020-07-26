defmodule AudioServer do
    use GenServer
  
    @conf Application.get_env :discord_lite_server, :network
    def start_link(port) do
        ip = @conf[:ip] || {127,0,0,1}
        GenServer.start_link(__MODULE__, [ip, port], []) # Start 'er up
    end
  
    def init [ip, port] do
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true, ip: ip])
      {:ok, %{socket: socket, client_address: nil, port: port}}
    end
  
    def handle_info({:send_data, data}, state) do
        if (state.client_address) do
            :gen_udp.send(state.socket, state.client_address, state.port, <<state.port::little-signed-32>> <> data)            
        end
        {:noreply, state}
    end
  
    def handle_info(:disconnect, state) do
        IO.inspect "udp disconnecting from #{inspect state.client_address} on port #{state.port}"
        :gen_udp.close(state.socket)
        {:stop, :normal, nil}
    end
  
    def handle_info({:udp, _socket, address, _port, data}, state) do
        GenServer.cast(MainServer, {:send_everyone, state.port, data})
        if (!state.client_address) do
            {:noreply, %{state | client_address: address}}
        else
            {:noreply, state}
        end
    end
  end  
  #{:ok, _pid} = Supervisor.start_link([{UDPServer, 2052}], strategy: :one_for_one)