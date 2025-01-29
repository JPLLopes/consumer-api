require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { 
    described_class.new(
      country: "US",
      brand: "BrandX",
      product_id: 123,
      product_name: "Sample Product",
      shop_name: "ShopA",
      product_category_id: 1,
      price: 19.99,
      url: "http://example.com/product"
    )
  }

  context "validations" do
    it "is valid with all attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without a country" do
      subject.country = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a brand" do
      subject.brand = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a product_id" do
      subject.product_id = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a product_name" do
      subject.product_name = nil
      expect(subject).not_to be_valid
    end

        it "is invalid without a shop_name" do
      subject.shop_name = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a product_category_id" do
      subject.product_category_id = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a price" do
      subject.price = nil
      expect(subject).not_to be_valid
    end

    it "is invalid without a url" do
      subject.url = nil
      expect(subject).not_to be_valid
    end

    it "validates uniqueness of product_id scoped to country and shop_name" do
      described_class.create!(
        country: "US",
        brand: "BrandY",
        product_id: 123,
        product_name: "Existing Product",
        shop_name: "ShopA",
        product_category_id: 2,
        price: 29.99,
        url: "http://example.com/another-product"
      )

      expect(subject).not_to be_valid
      expect(subject.errors[:product_id]).to include("must be unique for the same country and shop.")
    end
  end
end
