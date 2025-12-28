# frozen_string_literal: true

json.array! @quotes do |quote|
  json.extract! quote, :id, :customer_name, :customer_contact, :quote_date, :created_at

  json.line_items_count quote.line_items.size
  json.payments_count quote.payments.size

  json.totals do
    json.total quote.total
    json.total_paid quote.total_paid
    json.remaining_balance quote.remaining_balance
    json.fully_paid quote.fully_paid?
  end
end
