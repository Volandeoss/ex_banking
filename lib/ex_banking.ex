defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """
  alias ExBanking.User

  @doc """
  Hello world.

  ## Examples

      iex> ExBanking.hello()
      :world

  """

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}#Done
  def create_user(user) when is_binary(user) do
    case user?(user) do
      true -> {:error, :user_already_exists}
      false -> User.start_child(user)
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when (is_float(amount) or is_integer(amount)) and (is_binary(currency) and is_binary(user)) do
    with true <- user?(user),
    {:ok, result} <- User.deposit(user, amount, currency) do
      {:ok, result}
    else
      false -> {:error, :user_does_not_exist}
      {:error, reason} -> {:error, reason}
    end

  end

  def deposit(_,_,_), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    case user?(user) do
      true -> User.withdraw(user, amount, currency)
      false -> {:error, :user_does_not_exist}
    end

  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    case user?(user) do
      true -> User.show(user, currency)
      false -> {:error, :user_does_not_exist}
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    case User.withdraw(from_user, amount, currency) do
      {:ok, _} ->
        case User.deposit(to_user, amount, currency) do
          {:ok, _} ->
            {:ok, User.show(from_user, currency), User.show(to_user, currency)}

          error ->
            error
        end

      error ->
        error
    end
  end

  defp user?(user) when is_binary(user) do
    case Registry.lookup(ExBanking.Registry, user) do
      [] -> false
      _ -> true
    end
  end
end
