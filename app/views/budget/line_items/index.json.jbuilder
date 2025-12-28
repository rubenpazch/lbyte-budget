# frozen_string_literal: true

json.array! @line_items do |item|
  json.extract! item, :id, :description, :price, :category, :quantity, :created_at
  json.category_name item.category_name
  json.subtotal item.subtotal
end
