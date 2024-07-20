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



  def send(from_user, to_user, amount, currency) do
    case withdraw(from_user, amount, currency) do
      {:ok, _} ->
        case deposit(to_user, amount, currency) do
          {:ok, _} ->
            {:ok, show(from_user, currency), show(to_user, currency)}
          error -> error
        end
      error -> error
    end
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


  def handle_call({:withdraw, amount, currency}, _from, state) do
    new_value = Map.get(state,currency, 0) - amount


    {:reply, {:ok, new_value}, Map.put(state, currency, new_value)}
  end

  defp via_tuple(user) do
    {:via, Registry, {ExBanking.Registry, user}}
  end
end
