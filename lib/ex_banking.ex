defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """
  alias ExBanking.User

  # Done
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with {:not_binary_user, true} <- {:not_binary_user, is_binary(user)},
         {:user_already_exists, false} <- {:user_already_exists, user?(user)} do
      User.start_child(user)
    else
      {:not_binary_user, false} -> {:error, :wrong_arguments}
      {:user_already_exists, true} -> {:error, :user_already_exists}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    with {:wrong_arguments, true} <- {:wrong_arguments, arguments?(user, currency, amount)},
         {:user_does_not_exist, true} <- {:user_does_not_exist, user?(user)},
         {:ok, result} <- User.deposit(user, amount, currency) do
      {:ok, result}
    else
      {:wrong_arguments, false} -> {:error, :wrong_arguments}
      {:user_does_not_exist, false} -> {:error, :user_does_not_exist}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    with {:wrong_arguments, true} <- {:wrong_arguments, arguments?(user, currency, amount)},
         {:user_does_not_exist, true} <- {:user_does_not_exist, user?(user)} do
      User.withdraw(user, amount, currency)
    else
      {:wrong_arguments, false}-> {:error, :wrong_arguments}
      {:user_does_not_exist, false} -> {:error, :user_does_not_exist}
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    with {:not_binary_user, true} <- {:not_binary_user, is_binary(user)},
         {:not_binary_currency, true} <- {:not_binary_currency, is_binary(currency)},
         {:user_does_not_exist, true} <- {:user_does_not_exist, user?(user)} do
      User.show(user, currency)
    else
      {:not_binary_user, false} -> {:error, :wrong_arguments}
      {:not_binary_currency, false} -> {:error, :wrong_arguments}
      {:user_does_not_exist, false} -> {:error, :user_does_not_exist}
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
    with {:wrong_arguments, true} <-
           {:wrong_arguments, arguments?(from_user, to_user, currency, amount)},
         {:ok, _} <- user?(from_user, :sender),
         {:ok, _} <- user?(to_user, :receiver),
         {:too_many_requests_to_sender, {:ok, from}} <-
           {:too_many_requests_to_sender, User.withdraw(from_user, amount, currency)},
         {:too_many_requests_to_receiver, {:ok, to}} <-
           {:too_many_requests_to_receiver, User.deposit(to_user, amount, currency)} do
      {:ok, from, to}
    else
      {:too_many_requests_to_sender, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_sender}

      {:too_many_requests_to_receiver, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_receiver}

      {:too_many_requests_to_sender, {:error, :not_enough_money}}-> {:error, :not_enough_money}
      {:too_many_requests_to_receiver, {:error, :not_enough_money}}-> {:error, :not_enough_money}

      {:wrong_arguments, false} ->
        {:error, :wrong_arguments}

      {:error, :sender_does_not_exist} ->
        {:error, :sender_does_not_exist}

      {:error, :receiver_does_not_exist} ->
        {:error, :receiver_does_not_exist}
    end
  end

  def arguments?(from_user, to_user, currency, amount) do
    with {:not_binary_sender, true} <- {:not_binary_sender, is_binary(from_user)},
         {:not_binary_receiver, true} <- {:not_binary_receiver, is_binary(to_user)},
         {:not_binary_currency, true} <- {:not_binary_currency, is_binary(currency)},
         {:not_fl_int_amount, true} <- {:not_fl_int_amount, is_float(amount) or is_integer(amount)},
         {:not_positive, true} <- {:not_positive, amount >= 0} do
      true
    else
      {:not_binary_sender, false} -> false
      {:not_binary_receiver, false} -> false
      {:not_binary_currency, false} -> false
      {:not_fl_int_amount, false} -> false
      {:not_positive, false} -> false
    end
  end

  def arguments?(user, currency, amount) do
    with {:not_binary_user, true} <- {:not_binary_user, is_binary(user)},
         {:not_binary_currency, true} <- {:not_binary_currency, is_binary(currency)},
         {:not_fl_int_amount, true} <-
           {:not_fl_int_amount, is_float(amount) or is_integer(amount)},
         {:not_positive, true} <- {:not_positive, amount >= 0} do
      true
    else
      {:not_binary_user, false} -> false
      {:not_binary_currency, false} -> false
      {:not_fl_int_amount, false} -> false
      {:not_positive, false} -> false
    end
  end

  defp user?(user) when is_binary(user) do
    case Registry.lookup(ExBanking.Registry, user) do
      [] -> false
      _ -> true
    end
  end

  defp user?(user, :sender) when is_binary(user) do
    case Registry.lookup(ExBanking.Registry, user) do
      [] -> {:error, :sender_does_not_exist}
      _ -> {:ok, true}
    end
  end

  defp user?(user, :receiver) when is_binary(user) do
    case Registry.lookup(ExBanking.Registry, user) do
      [] -> {:error, :receiver_does_not_exist}
      _ -> {:ok, true}
    end
  end
end
