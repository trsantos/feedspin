class PreventNullExpirationDates < ActiveRecord::Migration[7.2]
  def change
    change_column_null(:users, :expiration_date, false, 1.month.from_now)
  end
end
