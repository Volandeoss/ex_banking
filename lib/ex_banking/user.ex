defmodule ExBanking.User do
  use GenServer

  @max_requests 10

  def start_child(user) do

    DynamicSupervisor.start_child(:dsup, {__MODULE__, user})
  end

  def start_link(user) do
    GenServer.start_link(__MODULE__, %{:req => 0, "USD" => 0}, name: via_tuple(user))
  end

  @impl true
  def init(_user) do
    {:ok, %{:req => 0, "USD" => 0}}
  end


  def increment_request_count(user) do
    GenServer.cast(via_tuple(user), :increment_request_count)
  end

  def deposit(user, amount, currency) do
    increment_request_count(user)
    GenServer.call(via_tuple(user), {:deposit, amount, currency, user})
  end

  def withdraw(user, amount, currency) do
    increment_request_count(user)
    GenServer.call(via_tuple(user), {:withdraw, amount, currency})

  end



  def show(user, currency) do
    increment_request_count(user)
    GenServer.call(via_tuple(user), {:show, currency})
  end

  @impl true
  def handle_call({:deposit, _amount, _currency, user}, _from, state) when state.req >= @max_requests do
    IO.inspect(state.req)
    {:reply, {:error, :too_many_requests_to_user}, state}
  end


  def handle_call({:deposit, amount, currency, user}, _from, state) when is_integer(amount) do
    [{pid, _}]=Registry.lookup(ExBanking.Registry, user)

    new_value = Map.get(state, currency, 0) + amount

    new_state =
      state
      |> Map.put(currency, new_value)

    Process.send_after(pid, :process_done, 3000)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:deposit, amount, currency, user}, _from, state) when is_float(amount) do
    IO.inspect(state.req)
    IO.inspect(user)
    new_value = Map.get(state, currency, 0) + Float.round(amount, 2)

    new_state =
      state
      |> Map.put(currency, new_value)
      |> Map.put(:req, state.req - 1)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:show, currency}, _from, state) do
    {:reply, {:ok, Map.get(state, currency, 0)}, state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    new_value = Map.get(state, currency, 0) - amount

    {:reply, {:ok, new_value}, Map.put(state, currency, new_value)}
  end



  @impl true
  def handle_cast(:increment_request_count, %{req: req} = state) do
    new_state = %{state | req: req + 1}
    {:noreply, new_state}
  end


  def handle_info(:process_done, state) do
    #send(self(),IO.puts("PROCESS DONE"))
    amount_of_req = Map.get(state, :req, 0)
    new_state = Map.put state, :req, max(amount_of_req-1, 0)|>IO.inspect
    {:noreply, new_state}
  end

  defp update_request_count(state, delta) do
    %{state | req: max(0, state[:req] + delta)}
  end

  defp via_tuple(user) do
    {:via, Registry, {ExBanking.Registry, user}}
  end

end
