defmodule MainServer do
    use GenServer

    def start_link _ do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init [] do
        {:ok, %{clients: []}}
    end

    def get_clients do
        GenServer.call(__MODULE__, :get_clients)
    end

    def handle_call(:get_clients, _from, state) do
        {:reply, state.clients, state}
    end

    def handle_cast({:add_client, pid}, state) do
        IO.inspect("Adding new client")
        IO.inspect([pid|state.clients])
        {:noreply, %{state | clients: [pid|state.clients]}}
    end

    def handle_cast({:kill_client, pid}, state) do
        IO.inspect("Killing client")
        IO.inspect(state.clients |> List.delete(pid))
        {:noreply, %{state | clients: state.clients |> List.delete(pid)}}
    end

    def handle_info({:send_everyone, from, data}, state) do
        state.clients |> Enum.each(fn client ->
            send(client, {:send_data, from, data})
        end)
        {:noreply, state}
    end
end