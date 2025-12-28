# frozen_string_literal: true

json.array! @payments do |payment|
  json.extract! payment, :id, :amount, :payment_date, :payment_method, :notes, :created_at
  json.payment_method_name payment.payment_method_name
end
