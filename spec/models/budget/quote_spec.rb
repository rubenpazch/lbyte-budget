# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::Quote, type: :model do
  describe 'associations' do
    it { expect(described_class.reflect_on_association(:line_items).macro).to eq(:has_many) }
    it { expect(described_class.reflect_on_association(:payments).macro).to eq(:has_many) }

    it 'destroys dependent line items' do
      quote = Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today)
      quote.line_items.create!(description: 'Item 1', price: 100, category: 'lente')

      expect { quote.destroy }.to change { Budget::LineItem.count }.by(-1)
    end

    it 'destroys dependent payments' do
      quote = Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today)
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'efectivo')

      expect { quote.destroy }.to change { Budget::Payment.count }.by(-1)
    end
  end

  describe 'validations' do
    it 'requires customer_name' do
      quote = Budget::Quote.new(quote_date: Date.today)
      expect(quote).not_to be_valid
      expect(quote.errors[:customer_name]).to include("can't be blank")
    end

    it 'sets quote_date on create if not provided' do
      quote = Budget::Quote.new(customer_name: 'John Doe')
      quote.valid?
      expect(quote.quote_date).to eq(Date.today)
    end

    it 'is valid with required attributes' do
      quote = Budget::Quote.new(customer_name: 'John Doe', quote_date: Date.today)
      expect(quote).to be_valid
    end
  end

  describe 'callbacks' do
    it 'sets quote_date before validation on create if not set' do
      quote = Budget::Quote.new(customer_name: 'John Doe')
      quote.valid?
      expect(quote.quote_date).not_to be_nil
    end

    it 'does not override quote_date if already set' do
      custom_date = Date.new(2025, 1, 1)
      quote = Budget::Quote.create!(customer_name: 'John Doe', quote_date: custom_date)
      expect(quote.quote_date).to eq(custom_date)
    end
  end

  describe 'scopes' do
    before do
      @old_quote = Budget::Quote.create!(customer_name: 'Old', quote_date: Date.today - 10.days)
      @new_quote = Budget::Quote.create!(customer_name: 'New', quote_date: Date.today)
    end

    describe '.recent' do
      it 'orders quotes by created_at desc' do
        quotes = Budget::Quote.recent
        expect(quotes.first).to eq(@new_quote)
      end
    end

    describe '.by_customer' do
      it 'finds quotes by customer name' do
        quotes = Budget::Quote.by_customer('Old')
        expect(quotes).to include(@old_quote)
        expect(quotes).not_to include(@new_quote)
      end

      it 'performs case-insensitive partial match' do
        quotes = Budget::Quote.by_customer('old')
        expect(quotes).to include(@old_quote)
      end
    end

    describe '.pending' do
      it 'returns quotes with unpaid balances' do
        @old_quote.line_items.create!(description: 'Test', price: 100, category: 'lente')
        @old_quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'efectivo')

        @new_quote.line_items.create!(description: 'Test', price: 100, category: 'lente')
        @new_quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')

        pending_quotes = Budget::Quote.pending
        expect(pending_quotes).to include(@old_quote)
        expect(pending_quotes).not_to include(@new_quote)
      end
    end
  end

  describe '#total' do
    it 'returns 0 when no line items' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      expect(quote.total).to eq(0)
    end

    it 'calculates total from all line items' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item 1', price: 100, quantity: 2, category: 'lente')
      quote.line_items.create!(description: 'Item 2', price: 50, quantity: 1, category: 'montura')

      expect(quote.total).to eq(250)
    end
  end

  describe '#total_paid' do
    it 'returns 0 when no payments' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      expect(quote.total_paid).to eq(0)
    end

    it 'calculates total from all payments' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'tarjeta')

      expect(quote.total_paid).to eq(150)
    end
  end

  describe '#remaining_balance' do
    it 'returns total when no payments' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 100, category: 'lente')

      expect(quote.remaining_balance).to eq(100)
    end

    it 'calculates remaining balance correctly' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 200, category: 'lente')
      quote.payments.create!(amount: 75, payment_date: Date.today, payment_method: 'efectivo')

      expect(quote.remaining_balance).to eq(125)
    end
  end

  describe '#fully_paid?' do
    it 'returns false when balance remains' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 100, category: 'lente')
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'efectivo')

      expect(quote.fully_paid?).to be false
    end

    it 'returns true when fully paid' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 100, category: 'lente')
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')

      expect(quote.fully_paid?).to be true
    end

    it 'returns true when overpaid' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 100, category: 'lente')
      quote.payments.create!(amount: 150, payment_date: Date.today, payment_method: 'efectivo')

      expect(quote.fully_paid?).to be true
    end
  end

  describe '#initial_payment' do
    it 'returns nil when no payments' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      expect(quote.initial_payment).to be_nil
    end

    it 'returns first payment by date' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')
      payment1 = quote.payments.create!(amount: 50, payment_date: Date.today - 1.day, payment_method: 'efectivo')

      expect(quote.initial_payment).to eq(payment1)
    end
  end

  describe '#category_breakdown' do
    it 'returns empty hash when no line items' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      expect(quote.category_breakdown).to eq({})
    end

    it 'groups totals by category' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Lentes 1', price: 100, category: 'lente')
      quote.line_items.create!(description: 'Lentes 2', price: 50, category: 'lente')
      quote.line_items.create!(description: 'Montura', price: 80, category: 'montura')

      breakdown = quote.category_breakdown
      expect(breakdown[:lente]).to eq(150)
      expect(breakdown[:montura]).to eq(80)
    end
  end

  describe '#summary' do
    it 'returns comprehensive quote summary' do
      quote = Budget::Quote.create!(
        customer_name: 'María González',
        customer_contact: '555-1234',
        quote_date: Date.today
      )
      quote.line_items.create!(description: 'Lentes', price: 150, category: 'lente')
      quote.payments.create!(amount: 75, payment_date: Date.today, payment_method: 'efectivo')

      summary = quote.summary

      expect(summary[:customer_name]).to eq('María González')
      expect(summary[:customer_contact]).to eq('555-1234')
      expect(summary[:line_items_count]).to eq(1)
      expect(summary[:total]).to eq(150)
      expect(summary[:total_paid]).to eq(75)
      expect(summary[:remaining_balance]).to eq(75)
      expect(summary[:fully_paid]).to be false
      expect(summary[:payments_count]).to eq(1)
      expect(summary[:category_breakdown][:lente]).to eq(150)
    end
  end

  describe '#to_s' do
    it 'formats quote for display' do
      quote = Budget::Quote.create!(
        customer_name: 'María González',
        customer_contact: '555-1234',
        quote_date: Date.new(2025, 11, 29),
        notes: 'Test quote'
      )
      quote.line_items.create!(description: 'Lentes', price: 150, category: 'lente')
      quote.payments.create!(amount: 75, payment_date: Date.today, payment_method: 'efectivo')

      output = quote.to_s

      expect(output).to include('PRESUPUESTO')
      expect(output).to include('María González')
      expect(output).to include('555-1234')
      expect(output).to include('29/11/2025')
      expect(output).to include('Test quote')
      expect(output).to include('Lentes')
      expect(output).to include('150.00')
      expect(output).to include('75.00')
      expect(output).to include('PENDIENTE')
    end

    it 'shows PAGADO COMPLETO when fully paid' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Item', price: 100, category: 'lente')
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')

      expect(quote.to_s).to include('PAGADO COMPLETO')
    end
  end

  describe '#add_line_item' do
    it 'creates a new line item' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)

      expect do
        quote.add_line_item(description: 'Test Item', price: 100, category: 'lente')
      end.to change { quote.line_items.count }.by(1)

      item = quote.line_items.last
      expect(item.description).to eq('Test Item')
      expect(item.price).to eq(100)
      expect(item.category).to eq('lente')
    end

    it 'accepts quantity parameter' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.add_line_item(description: 'Test', price: 50, category: 'lente', quantity: 3)

      expect(quote.line_items.last.quantity).to eq(3)
    end

    it 'defaults category to other' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.add_line_item(description: 'Test', price: 50)

      expect(quote.line_items.last.category).to eq('other')
    end
  end

  describe '#add_payment' do
    it 'creates a new payment' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)

      expect do
        quote.add_payment(amount: 100, payment_method: 'tarjeta')
      end.to change { quote.payments.count }.by(1)

      payment = quote.payments.last
      expect(payment.amount).to eq(100)
      expect(payment.payment_method).to eq('tarjeta')
    end

    it 'accepts payment_date parameter' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      custom_date = Date.new(2025, 1, 1)
      quote.add_payment(amount: 50, payment_date: custom_date, payment_method: 'efectivo')

      expect(quote.payments.last.payment_date).to eq(custom_date)
    end

    it 'defaults payment_date to current time' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)

      Timecop.freeze(Time.local(2025, 11, 29, 12, 0, 0)) do
        quote.add_payment(amount: 50, payment_method: 'efectivo')
        expect(quote.payments.last.payment_date).to eq(Date.new(2025, 11, 29))
      end
    end

    it 'accepts notes parameter' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.add_payment(amount: 100, payment_method: 'efectivo', notes: 'Adelanto')

      expect(quote.payments.last.notes).to eq('Adelanto')
    end

    it 'defaults payment_method to efectivo' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.add_payment(amount: 50)

      expect(quote.payments.last.payment_method).to eq('efectivo')
    end
  end

  describe 'table_name' do
    it 'uses budget_quotes table' do
      expect(Budget::Quote.table_name).to eq('budget_quotes')
    end
  end
end
