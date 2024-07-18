defmodule ExBanking.User do
  use GenServer

  def start_link(user) do
    GenServer.start_link(__MODULE__, %{"USD" => 0}, name: via_tuple(user))
  end

  @impl true
  def init(_user) do
    {:ok, %{"USD" => 0}}
  end

  def withdraw(user, amount, currency) do
    GenServer.call(via_tuple(user), {:withdraw, amount, currency})
  end

  def deposit(user, amount, currency) do
    GenServer.call(via_tuple(user), {:deposit, user, amount, currency})
  end

  def show(user, currency) do
    GenServer.call(via_tuple(user), {:show, user, currency})
  end

  def handle_call({:deposit, user, amount, currency}, _from, state) do
    new_value = Map.get(state, currency, 0) + amount

    new_state =
      state
      |> Map.put(currency, new_value)

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:show, user, currency}, _from, state) do
    {:reply, {:ok, Map.get(state, currency, 0)}, state}
  end

  #here is bad
  def handle_call({:withdraw, user, amount, currency}, _from, state) do
    new_state = Map.get(state,currency, 0) - amount

    {:reply, {:ok, new_state}, state}
  end

  defp via_tuple(user) do
    {:via, Registry, {ExBanking.Registry, user}}
  end
end
