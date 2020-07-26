defmodule TcpServer do
    use GenServer

    def start_link(ip, port) do
        GenServer.start_link(__MODULE__,[ip,port],[])
    end

    def init [ip,port] do
        Process.send(self(), :start_listening, [])
        {:ok, %{ip: ip,port: port}}
    end

    def handle_info(:start_listening, state) do
        {:ok,listen_socket}= :gen_tcp.listen(state.port,[:binary,{:packet, 0},{:active,true},{:ip,state.ip}])
        {:ok,socket } = :gen_tcp.accept listen_socket
        {:noreply, state |> Map.merge(%{socket: socket})}
    end

    def handle_info({:tcp,socket,packet},state) do
        IO.inspect packet, label: "incoming packet"
        :gen_tcp.send socket,"Hi Blackode \n"
        {:noreply,state}
    end

    def handle_info({:tcp_closed,socket},state) do
        IO.inspect "Socket has been closed by #{IO.inspect socket}"
        {:noreply,state}
    end

    def handle_info({:tcp_error,socket,reason},state) do
        IO.inspect socket,label: "Connection closed with #{IO.inspect socket} due to #{reason}"
        {:noreply,state}
    end
end