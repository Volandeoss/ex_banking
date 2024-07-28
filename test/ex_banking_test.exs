defmodule ExBankingTest do
  use ExUnit.Case
  alias ExBanking

  @user1 "user1"
  @user2 "user2"
  @currency "USD"
  @initial_amount 100

  setup do
    Application.stop(:ex_banking)
    :ok = Application.start(:ex_banking)
    :ok
  end

  test "create user with valid input" do
    assert :ok == ExBanking.create_user(@user1)
  end

  test "create user with invalid input" do
    assert {:error, :wrong_arguments} == ExBanking.create_user(123)
  end

  test "create user that already exists" do
    ExBanking.create_user(@user1)
    assert {:error, :user_already_exists} == ExBanking.create_user(@user1)
  end

  test "deposit with valid input" do
    ExBanking.create_user(@user1)
    assert {:ok, @initial_amount} == ExBanking.deposit(@user1, @initial_amount, @currency)
  end

  test "deposit with invalid user" do
    assert {:error, :user_does_not_exist} == ExBanking.deposit(@user1, @initial_amount, @currency)
  end

  test "deposit with invalid arguments" do
    assert {:error, :wrong_arguments} == ExBanking.deposit(@user1, -@initial_amount, @currency)
  end

  test "withdraw with valid input" do
    ExBanking.create_user(@user1)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:ok, 50} == ExBanking.withdraw(@user1, 50, @currency)
  end

  test "withdraw with insufficient funds" do
    ExBanking.create_user(@user1)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:error, :not_enough_money} == ExBanking.withdraw(@user1, @initial_amount + 1, @currency)
  end

  test "withdraw with invalid user" do
    assert {:error, :user_does_not_exist} == ExBanking.withdraw(@user1, @initial_amount, @currency)
  end

  test "get balance with valid input" do
    ExBanking.create_user(@user1)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:ok, @initial_amount} == ExBanking.get_balance(@user1, @currency)
  end

  test "get balance with invalid user" do
    assert {:error, :user_does_not_exist} == ExBanking.get_balance(@user1, @currency)
  end

  test "send with valid input" do
    ExBanking.create_user(@user1)
    ExBanking.create_user(@user2)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:ok, 50, 50} == ExBanking.send(@user1, @user2, 50, @currency)
  end

  test "send with insufficient funds" do
    ExBanking.create_user(@user1)
    ExBanking.create_user(@user2)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:error, :not_enough_money} == ExBanking.send(@user1, @user2, @initial_amount + 1, @currency)
  end

  test "send with invalid sender" do
    ExBanking.create_user(@user2)
    assert {:error, :sender_does_not_exist} == ExBanking.send(@user1, @user2, 50, @currency)
  end

  test "send with invalid receiver" do
    ExBanking.create_user(@user1)
    ExBanking.deposit(@user1, @initial_amount, @currency)
    assert {:error, :receiver_does_not_exist} == ExBanking.send(@user1, @user2, 50, @currency)
  end

  test "too many requests to user" do
    ExBanking.create_user(@user1)
    ExBanking.deposit(@user1, @initial_amount, @currency)

    Enum.each(1..10, fn _ ->
      ExBanking.get_balance(@user1, @currency)
    end)

    assert {:error, :too_many_requests_to_user} == ExBanking.get_balance(@user1, @currency)
  end
end
