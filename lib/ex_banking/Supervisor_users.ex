defmodule ExBanking.SupervisorUsers do
  use DynamicSupervisor

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_child(any(), any(), any()) :: none()
  def start_child(username, _amount, _currency) do
    # This will start child by calling MyWorker.start_link(init_arg, foo, bar, baz)
    Supervisor.start_child(__MODULE__, %{username: username})
  end

  @impl true
  def init(init_arg) do
    children = []

    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
