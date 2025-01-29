class Product < ApplicationRecord
    validates :country, :brand, :product_id, :product_name, :shop_name, :product_category_id, :price, :url, presence: true
    validates :product_id, uniqueness: { 
        scope: [:country, :shop_name], 
        message: "must be unique for the same country and shop."
    }
end