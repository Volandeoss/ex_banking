defmodule ExBanking.User do
  use GenServer

  @max_requests 10

  def start_child(user) do
    DynamicSupervisor.start_child(:dsup, {__MODULE__, user})
    |> response()
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
    GenServer.call(via_tuple(user), {:withdraw, amount, currency, user})
  end

  def show(user, currency) do
    increment_request_count(user)
    GenServer.call(via_tuple(user), {:show, currency, user})
  end

  @impl true
  def handle_call({:deposit, _amount, _currency, user}, _from, state)
      when state.req >= @max_requests do
    process_done(user)
    {:reply, {:error, :too_many_requests_to_user}, state}
  end

  def handle_call({:deposit, amount, currency, user}, _from, state) do
    amount_format =
      (amount + 0.0)
      |> Float.round(2)

    new_value = (Map.get(state, currency, 0) + amount_format) |> Float.round(2)

    new_state =
      state
      |> Map.put(currency, new_value)

    process_done(user)
    {:reply, {:ok, new_value}, new_state}
  end

  def handle_call({:show, _currency, user}, _from, state) when state.req >= @max_requests do
    process_done(user)
    {:reply, {:error, :too_many_requests_to_user}, state}
  end

  def handle_call({:show, currency, user}, _from, state) do
    process_done(user)
    {:reply, {:ok, Map.get(state, currency, 0)}, state}
  end

  def handle_call({:withdraw, _amount, _currency, user}, _from, state)
      when state.req >= @max_requests do
    process_done(user)
    {:reply, {:error, :too_many_requests_to_user}, state}
  end

  def handle_call({:withdraw, amount, currency, user}, _from, state) do
    amount_format =
      (amount + 0.0)
      |> Float.round(2)

    new_value = (Map.get(state, currency, 0) - amount_format) |> Float.round(2)

    if new_value < 0 do
      process_done(user)
      {:reply, {:error, :not_enough_money}, state}
    else
      new_state = Map.put(state, currency, new_value)
      process_done(user)
      {:reply, {:ok, new_value}, new_state}
    end
  end

  @impl true
  def handle_cast(:increment_request_count, %{req: req} = state) do
    new_state = %{state | req: req + 1}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:process_done, state) do
    amount_of_req = Map.get(state, :req, 0)
    new_state = Map.put(state, :req, max(amount_of_req - 1, 0))
    {:noreply, new_state}
  end

  defp process_done(user) do
    [{pid, _}] = Registry.lookup(ExBanking.Registry, user)
    Process.send_after(pid, :process_done, 3000)
  end

  defp response({:ok, _}), do: :ok
  defp response({:error, reason}), do: {:error, reason}

  defp via_tuple(user) do
    {:via, Registry, {ExBanking.Registry, user}}
  end
end
