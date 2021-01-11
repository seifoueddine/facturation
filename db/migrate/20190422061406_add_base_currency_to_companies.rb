class AddBaseCurrencyToCompanies < ActiveRecord::Migration[6.0]
  def change
    add_column :companies, :base_currency_id, :integer, default: 1
  end
end
