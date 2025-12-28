#!/usr/bin/env ruby
# frozen_string_literal: true

# This example requires a Rails environment with the Budget engine loaded
# Run from a Rails app that has the budget gem installed:
#   rails runner examples/basic_usage.rb

puts '=' * 70
puts 'EJEMPLO DE USO DEL SISTEMA DE PRESUPUESTOS'
puts '=' * 70
puts

# 1. Create a new quote for a customer
puts '1. Creando un nuevo presupuesto para María González...'
quote = Budget::Quote.create!(
  customer_name: 'María González',
  customer_contact: '555-1234',
  notes: 'Prefiere montura liviana'
)
puts "✓ Presupuesto ##{quote.id} creado"
puts

# 2. Add line items (lentes, montura, tratamiento)
puts '2. Agregando artículos al presupuesto...'

# Add lenses
quote.add_line_item(
  description: 'Lentes progresivos alta gama',
  price: 150.00,
  category: 'lente'
)
puts '✓ Agregado: Lentes progresivos - $150.00'

# Add frame
quote.add_line_item(
  description: 'Montura de titanio ligera',
  price: 80.00,
  category: 'montura'
)
puts '✓ Agregado: Montura de titanio - $80.00'

# Add treatment
quote.add_line_item(
  description: 'Tratamiento anti-reflejante',
  price: 35.00,
  category: 'tratamiento'
)
puts '✓ Agregado: Tratamiento anti-reflejante - $35.00'

# Add additional treatment
quote.add_line_item(
  description: 'Protección UV',
  price: 25.00,
  category: 'tratamiento'
)
puts '✓ Agregado: Protección UV - $25.00'

# Add case
quote.add_line_item(
  description: 'Estuche premium',
  price: 10.00,
  category: 'other'
)
puts '✓ Agregado: Estuche premium - $10.00'
puts

# 3. Display quote
puts '3. Presupuesto completo:'
puts quote
puts

# 4. Add initial payment (adelanto)
puts '4. Cliente realiza adelanto del 50%...'
adelanto_amount = quote.total * 0.5
quote.add_payment(
  amount: adelanto_amount,
  payment_method: 'efectivo',
  notes: 'Adelanto inicial (50%)'
)
puts "✓ Adelanto de $#{format('%.2f', adelanto_amount)} registrado"
puts "   Saldo pendiente: $#{format('%.2f', quote.remaining_balance)}"
puts

# 5. Display updated quote
puts '5. Presupuesto actualizado:'
puts quote
puts

# Simulate time passing and customer returning
puts '=' * 70
puts '... 2 semanas después ...'
puts '=' * 70
puts

# 6. Customer returns to complete payment
puts '6. Cliente regresa para completar el pago...'
remaining = quote.remaining_balance
quote.add_payment(
  amount: remaining,
  payment_method: 'tarjeta',
  notes: 'Pago final - retira lentes'
)
puts "✓ Pago final de $#{format('%.2f', remaining)} registrado"
puts "✓ Estado: #{quote.fully_paid? ? 'PAGADO COMPLETO ✓' : 'PENDIENTE'}"
puts

# 7. Display final quote
puts '7. Presupuesto final:'
puts quote
puts

# 8. Display summary
puts '8. Resumen del presupuesto:'
summary = quote.summary
puts "   ID: #{summary[:id]}"
puts "   Cliente: #{summary[:customer_name]}"
puts "   Total: $#{format('%.2f', summary[:total])}"
puts "   Pagado: $#{format('%.2f', summary[:total_paid])}"
puts "   Pendiente: $#{format('%.2f', summary[:remaining_balance])}"
puts "   Estado: #{summary[:fully_paid] ? 'COMPLETO' : 'PENDIENTE'}"
puts
puts '   Desglose por categoría:'
summary[:category_breakdown].each do |category, amount|
  puts "   - #{category}: $#{format('%.2f', amount)}"
end
puts

puts '=' * 70
puts 'EJEMPLO COMPLETADO'
puts '=' * 70
