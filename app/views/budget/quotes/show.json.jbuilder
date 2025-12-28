# frozen_string_literal: true

json.extract! @quote, :id, :customer_name, :customer_contact, :notes, :quote_date, :created_at, :updated_at

json.line_items @quote.line_items do |item|
  json.extract! item, :id, :description, :price, :category, :quantity, :created_at
  json.category_name item.category_name
  json.subtotal item.subtotal
end

json.payments @quote.payments.ordered do |payment|
  json.extract! payment, :id, :amount, :payment_date, :payment_method, :notes, :created_at
  json.payment_method_name payment.payment_method_name
end

json.totals do
  json.total @quote.total
  json.total_paid @quote.total_paid
  json.remaining_balance @quote.remaining_balance
  json.fully_paid @quote.fully_paid?
end

json.category_breakdown @quote.category_breakdown
