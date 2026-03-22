require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "index redirects to first on_budget account" do
    get accounts_path
    assert_redirected_to account_path(accounts(:chequing))
  end

  test "show renders the account register" do
    get account_path(accounts(:chequing))
    assert_response :success
    assert_select ".fb-sidebar"
    assert_select ".fb-account-header"
    assert_select ".fb-table"
  end

  test "show displays account name" do
    get account_path(accounts(:chequing))
    assert_select ".fb-account-header__name", "Chequing"
  end

  test "show displays transactions for the account" do
    get account_path(accounts(:chequing))
    assert_select ".fb-table__row"
  end

  test "show loads all accounts in sidebar" do
    get account_path(accounts(:chequing))
    assert_select ".fb-sidebar__account-row", count: Account.count
  end

  test "show displays empty state when account has no transactions" do
    get account_path(accounts(:savings))
    assert_select "p", text: "No transactions yet"
  end
end
