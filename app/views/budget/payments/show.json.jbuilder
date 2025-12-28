# frozen_string_literal: true

json.extract! @payment, :id, :amount, :payment_date, :payment_method, :notes, :created_at, :updated_at
json.payment_method_name @payment.payment_method_name
json.quote_id @payment.budget_quote_id
