#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick Test Examples - Shows what the test suite validates
# Run from a Rails app that has the budget gem installed:
#   rails runner examples/test_examples.rb

puts '=' * 70
puts 'BUDGET GEM - TEST EXAMPLES'
puts '=' * 70
puts

# Example 1: LineItem validation
puts '1. LineItem - Category Validation'
puts '-' * 70
quote = Budget::Quote.create!(customer_name: 'Test Customer')
item1 = quote.line_items.create!(description: 'Lente', price: 100, category: 'lente')
item2 = quote.line_items.build(description: 'Invalid', price: 50, category: 'invalid_cat')
item2.valid? # This will fail validation
puts "Valid category ('lente'): #{item1.category}"
puts "Invalid category validation: #{item2.errors[:category].join(', ')}" if item2.errors[:category].any?
puts

# Example 2: Payment method validation
puts '2. Payment - Method Validation'
puts '-' * 70
payment1 = quote.payments.create!(amount: 100, payment_method: 'tarjeta')
payment2 = quote.payments.create!(amount: 50, payment_method: 'efectivo')
puts "tarjeta → #{payment1.payment_method}"
puts "efectivo → #{payment2.payment_method}"
puts

# Example 3: Quote calculations
puts '3. Quote - Total Calculations'
puts '-' * 70
calc_quote = Budget::Quote.create!(customer_name: 'Test Customer')
calc_quote.add_line_item(description: 'Lente', price: 150.0, category: 'lente')
calc_quote.add_line_item(description: 'Montura', price: 80.0, category: 'montura')
calc_quote.add_line_item(description: 'Tratamiento', price: 35.0, category: 'tratamiento', quantity: 2)
puts 'Items: Lente ($150) + Montura ($80) + Tratamiento ($35 x 2)'
puts "Total: $#{calc_quote.total}"
puts "Category breakdown: #{calc_quote.category_breakdown}"
puts

# Example 4: Payment tracking
puts '4. Quote - Payment Tracking'
puts '-' * 70
calc_quote.add_payment(amount: 150.0, notes: 'Adelanto (50%)')
puts "After adelanto: Paid=$#{calc_quote.total_paid}, Remaining=$#{calc_quote.remaining_balance}"
calc_quote.add_payment(amount: calc_quote.remaining_balance, notes: 'Final payment')
puts "After final payment: Paid=$#{calc_quote.total_paid}, Remaining=$#{calc_quote.remaining_balance}"
puts "Fully paid? #{quote.fully_paid?}"
puts

# Example 5: Type conversions
puts '5. Type Conversions'
puts '-' * 70
item = Budget::LineItem.new(description: 'Test', price: '99.99', quantity: '3')
puts "String price '99.99' → #{item.price.class}: #{item.price}"
puts "String quantity '3' → #{item.quantity.class}: #{item.quantity}"
puts "Subtotal: $#{item.subtotal}"
puts

# Example 6: Edge cases
puts '6. Edge Cases'
puts '-' * 70
edge_quote = Budget.create_quote(customer_name: 'Edge Test')
edge_quote.add_line_item(description: 'Item', price: 100.0)
edge_quote.add_payment(amount: 150.0) # Overpayment
puts 'Total: $100, Paid: $150'
puts "Remaining balance (overpayment): $#{edge_quote.remaining_balance}"
puts "Fully paid? #{edge_quote.fully_paid?}"
puts

# Example 7: Spanish formatting
puts '7. Spanish Translations'
puts '-' * 70
categories = %i[lente montura tratamiento other]
categories.each do |cat|
  item = Budget::LineItem.new(description: 'Test', price: 50, category: cat)
  puts "#{cat} → #{item.category_name}"
end
puts
payment_methods = %w[efectivo tarjeta transferencia cheque other]
payment_methods.each do |method|
  payment = Budget::Payment.new(amount: 50, payment_method: method)
  puts "#{method} → #{payment.payment_method_name}"
end
puts

# Example 8: Complete workflow
puts '8. Complete Workflow (Integration Test)'
puts '-' * 70
complete_quote = Budget.create_quote(
  customer_name: 'María González',
  customer_contact: '555-1234'
)
complete_quote.add_line_item(description: 'Lentes progresivos', price: 150.0, category: :lente)
complete_quote.add_line_item(description: 'Montura titanio', price: 80.0, category: :montura)
complete_quote.add_line_item(description: 'Anti-reflejante', price: 35.0, category: :tratamiento)

puts "Total: $#{complete_quote.total}"
adelanto = complete_quote.total * 0.5
complete_quote.add_payment(amount: adelanto, notes: 'Adelanto 50%')
puts "After 50% adelanto: Remaining=$#{complete_quote.remaining_balance}"
complete_quote.add_payment(amount: complete_quote.remaining_balance, notes: 'Pago final')
puts "After final payment: Status=#{complete_quote.fully_paid? ? 'COMPLETO' : 'PENDIENTE'}"
puts

puts '=' * 70
puts 'All examples demonstrate test coverage scenarios'
puts "Run 'bundle exec rspec' to execute the full test suite"
puts '=' * 70
