require "application_system_test_case"

class AccountRegisterTest < ApplicationSystemTestCase
  test "visiting accounts shows the register" do
    visit accounts_path

    # Should redirect to first on-budget account (Chequing)
    assert_selector ".fb-top-nav"
    assert_selector ".fb-sidebar"
    assert_selector ".fb-account-header__name", text: "Chequing"
  end

  test "sidebar shows accounts grouped by budget status" do
    visit account_path(accounts(:chequing))

    within ".fb-sidebar" do
      # CSS text-transform: uppercase causes headless Chrome to return uppercase text;
      # assert_selector text: matches are case-sensitive against browser-computed text.
      assert_selector ".fb-sidebar__section-label--budget", text: "ON-BUDGET"
      assert_selector ".fb-sidebar__type-label", text: "CASH"
      assert_text "Chequing"
      assert_text "Savings"
      assert_selector ".fb-sidebar__type-label", text: "CREDIT"
      assert_text "Visa"
      assert_selector ".fb-sidebar__section-label--tracking", text: "TRACKING"
      assert_selector ".fb-sidebar__type-label", text: "LOANS"
      assert_text "Mortgage"
      assert_selector ".fb-sidebar__type-label", text: "INVESTMENTS"
      assert_text "TFSA"
      assert_text "RRSP"
      assert_text "Net Worth"
    end
  end

  test "transaction table shows entries" do
    visit account_path(accounts(:chequing))

    within ".fb-table__body" do
      assert_text "Loblaws"
      assert_text "Groceries"
      assert_text "$52.30"
    end
  end

  test "legend bar is visible" do
    visit account_path(accounts(:chequing))

    within ".fb-legend" do
      assert_text "Uncleared"
      assert_text "Cleared"
      assert_text "Reconciled"
      assert_text "Scheduled"
    end
  end

  test "clicking another account switches the register" do
    visit account_path(accounts(:chequing))

    within ".fb-sidebar" do
      click_link "Savings"
    end

    assert_selector ".fb-account-header__name", text: "Savings"
  end

  test "top nav highlights Accounts" do
    visit account_path(accounts(:chequing))

    assert_selector ".fb-top-nav__nav-link--active", text: "Accounts"
  end
end
