require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  def setup
    @ledger = ledgers(:personal)
    @user = users(:jason)
    @ledger_membership = ledger_memberships(:jason_personal)

    @txn = transactions(:grocery_expense)
    @line = transaction_lines(:grocery_chequing_line)
    @account = accounts(:chequing)
    @payee = payees(:loblaws)
    @category = categories(:groceries)

    @other_account = accounts(:savings)

    @categories_by_account = @ledger.categories.index_by(&:account_id)
  end

  test "edit action renders with correct locals for cleared transaction" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    get edit_transaction_path(@txn, account_id: @account.id)

    assert_response :success
    assert_match /transaction_#{@txn.id}_edit/, response.body
    assert_match @txn.date.to_s, response.body
    assert_match @payee.name, response.body
    assert_match @category.name, response.body
  end

  test "edit action renders with correct locals for reconciled transaction" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "reconciled")
    @line_reconciled = @txn.transaction_lines.find { |l| l.account_id == @account.id }

    get edit_transaction_path(@txn, account_id: @account.id)

    assert_response :success
    assert_match /transaction_#{@txn.id}_edit/, response.body
  end

  test "edit action requires account_id parameter" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    get edit_transaction_path(@txn)

    assert_response :not_found
  end

  test "edit action returns not found when line does not exist for account" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    get edit_transaction_path(@txn, account_id: 99999)

    assert_response :not_found
  end

  test "update action requires account_id parameter" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    put transaction_path(@txn),
       params: { transaction_entry: { date: "2026-03-16" } }

    assert_response :bad_request
  end

  test "update action returns not found when line does not exist for account" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

put transaction_path(@txn),
        params: { transaction_entry: { account_id: 99999, date: "2026-03-16" } }

    assert_response :not_found
  end

  test "update action blocks reconciled transactions" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "reconciled")

put transaction_path(@txn),
        params: { transaction_entry: { account_id: @account.id, date: "2026-03-16" } }

    assert_response :forbidden
  end

  test "update action succeeds for uncleared transaction" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "2026-03-16", memo: "Updated memo" }
        }

    assert_response :success
    assert_equal "2026-03-16", @txn.reload.date.to_s
    assert_equal "Updated memo", @txn.reload.memo
  end

test "update action succeeds for cleared transaction" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "cleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "2026-03-16" }
        }

    assert_response :success
    assert_equal "2026-03-16", @txn.reload.date.to_s
  end

test "update action renders turbo_stream on success" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "2026-03-16" }
        }

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /transaction_#{@txn.id}"/, response.body
  end

  test "update action responds with turbo-stream content type so Turbo processes it instead of rendering as text" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "2026-03-16" }
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    assert_response :success
    assert_includes response.content_type, "text/vnd.turbo-stream.html"
  end

test "update action renders turbo_stream with errors on failure" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: {
            account_id: @account.id,
            transaction_lines_attributes: [
              { id: @line.id, amount: 1000 }
            ]
          }
        }

    assert_response :unprocessable_entity
    assert_match /turbo-stream/, response.body
    assert_match /transaction_#{@txn.id}_edit"/, response.body
  end

  test "update action validates date is present" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "" }
        }

    assert_response :unprocessable_entity
    assert_match(/transaction_#{@txn.id}_edit/, response.body)
  end

test "update action validates transaction lines sum to zero" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: {
            account_id: @account.id,
            transaction_lines_attributes: [
              { id: @line.id, amount: 1000 }
            ]
          }
        }

    assert_response :unprocessable_entity
    assert_match(/transaction_#{@txn.id}_edit/, response.body)
  end

  test "update action updates payee" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, date: "2026-03-16" }
        }

    assert_response :success
    assert_equal @payee.id, @txn.reload.payee_id
  end

test "update action updates memo" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: { account_id: @account.id, memo: "New memo" }
        }

    assert_response :success
    assert_equal "New memo", @txn.reload.memo
  end

test "update action renders edit form with errors when validation fails" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    @txn.update!(status: "uncleared")

    put transaction_path(@txn),
        params: {
          transaction_entry: {
            account_id: @account.id,
            transaction_lines_attributes: [
              { id: @line.id, amount: 5000 }
            ]
          }
        }

    assert_response :unprocessable_entity
    assert_match(/transaction_#{@txn.id}_edit/, response.body)
  end
end
