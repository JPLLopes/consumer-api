class AddUniqueIndexToProducts < ActiveRecord::Migration[8.0]
  def change
    add_index :products, [:product_id, :country, :shop_name], unique: true, name: 'unique_index_on_product_country_shop'
  end
end
