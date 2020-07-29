defmodule ClientServer do
    use GenServer

    def start_link(port, listen_socket) do
        GenServer.start_link(__MODULE__, [port, listen_socket], [])
    end

    def init [port, listen_socket] do
        {:ok, socket} = :gen_tcp.accept listen_socket
        {:ok, audio_pid} = AudioServer.start_link(port)
        :gen_tcp.send socket, <<port::little-signed-32>>
        {:ok, %{port: port, audio_pid: audio_pid}}
    end

    def handle_info({:send_data, from, data}, %{port: port, audio_pid: audio_pid}=state) when from != port do
        send(audio_pid, {:send_data, from, data})
        {:noreply, state}
    end

    def handle_info({:send_data, _from, _data}, state) do
        {:noreply, state}
    end

    def handle_info({:tcp, socket, "disconnect"}, state) do
        IO.inspect "tcp disconnecting from socket #{inspect socket}"
        :gen_tcp.close socket
        send(state.audio_pid, :disconnect)
        GenServer.cast(ChannelServer, {:remove_client, self()})
        {:stop, :normal, nil}
    end

    def handle_info({:tcp, socket, packet}, state) do
        IO.inspect packet, label: "Unknown packet from socket #{inspect socket}"
        {:noreply,state}
    end

    def handle_info({:tcp_closed, socket}, state) do
        IO.inspect "Socket has been closed with #{inspect socket}"
        send(state.audio_pid, :disconnect)
        GenServer.cast(ChannelServer, {:remove_client, self()})
        {:stop, :normal, nil}
    end

    def handle_info({:tcp_error, socket, reason},state) do
        IO.inspect socket,label: "Connection closed with #{inspect socket} due to #{reason}"
        send(state.audio_pid, :disconnect)
        GenServer.cast(ChannelServer, {:remove_client, self()})
        {:stop, :normal, nil}
    end
end