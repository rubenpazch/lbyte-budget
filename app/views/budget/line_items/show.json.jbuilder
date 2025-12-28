# frozen_string_literal: true

json.extract! @line_item, :id, :description, :price, :category, :quantity, :created_at, :updated_at
json.category_name @line_item.category_name
json.subtotal @line_item.subtotal
json.quote_id @line_item.budget_quote_id
