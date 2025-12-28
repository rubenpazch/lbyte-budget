# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::Payment, type: :model do
  let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

  describe 'associations' do
    it { expect(described_class.reflect_on_association(:quote).macro).to eq(:belongs_to) }

    it 'belongs to a quote' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )
      expect(payment.quote).to eq(quote)
    end
  end

  describe 'validations' do
    it 'requires amount' do
      payment = Budget::Payment.new(
        payment_date: Date.today,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("can't be blank")
    end

    it 'requires amount to be greater than 0' do
      payment = Budget::Payment.new(
        amount: 0,
        payment_date: Date.today,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include('must be greater than 0')
    end

    it 'accepts valid amount' do
      payment = Budget::Payment.new(
        amount: 0.01,
        payment_date: Date.today,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      expect(payment).to be_valid
    end

    it 'sets default payment_date when nil' do
      payment = Budget::Payment.new(
        amount: 100,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      payment.valid?
      expect(payment.payment_date).to eq(Date.today)
    end

    it 'sets default payment_method to efectivo when nil' do
      payment = Budget::Payment.new(
        amount: 100,
        payment_date: Date.today,
        budget_quote_id: quote.id
      )
      payment.payment_method = nil
      payment.valid?
      expect(payment.payment_method).to eq('efectivo')
    end

    it 'is valid with all required attributes' do
      payment = Budget::Payment.new(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      expect(payment).to be_valid
    end
  end

  describe 'callbacks' do
    it 'sets default payment_date to current date if not provided' do
      payment = Budget::Payment.new(
        amount: 100,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      payment.valid?
      expect(payment.payment_date).to eq(Date.today)
    end

    it 'does not override payment_date if already set' do
      custom_date = Date.new(2025, 1, 1)
      payment = Budget::Payment.create!(
        amount: 100,
        payment_date: custom_date,
        payment_method: 'efectivo',
        budget_quote_id: quote.id
      )
      expect(payment.payment_date).to eq(custom_date)
    end

    it 'sets default payment_method to efectivo if not provided' do
      payment = Budget::Payment.new(
        amount: 100,
        payment_date: Date.today,
        budget_quote_id: quote.id
      )
      payment.valid?
      expect(payment.payment_method).to eq('efectivo')
    end
  end

  describe 'PAYMENT_METHODS constant' do
    it 'defines all available payment methods' do
      expect(Budget::Payment::PAYMENT_METHODS).to eq(%w[efectivo tarjeta transferencia cheque other])
    end
  end

  describe '#payment_method_name' do
    it 'returns Spanish name for efectivo' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )
      expect(payment.payment_method_name).to eq('Efectivo')
    end

    it 'returns Spanish name for tarjeta' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'tarjeta'
      )
      expect(payment.payment_method_name).to eq('Tarjeta')
    end

    it 'returns Spanish name for transferencia' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'transferencia'
      )
      expect(payment.payment_method_name).to eq('Transferencia')
    end

    it 'returns Spanish name for cheque' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'cheque'
      )
      expect(payment.payment_method_name).to eq('Cheque')
    end

    it 'returns Spanish name for other' do
      payment = quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'other'
      )
      expect(payment.payment_method_name).to eq('Otro')
    end

    it 'returns capitalized method for unknown methods' do
      payment = quote.payments.build(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'custom'
      )
      expect(payment.payment_method_name).to eq('Custom')
    end
  end

  describe '#to_s' do
    it 'formats payment with all details' do
      payment = quote.payments.create!(
        amount: 150.00,
        payment_date: Date.new(2025, 11, 29),
        payment_method: 'tarjeta',
        notes: 'Adelanto 50%'
      )

      output = payment.to_s

      expect(output).to include('29/11/2025')
      expect(output).to include('150.00')
      expect(output).to include('Tarjeta')
      expect(output).to include('Adelanto 50%')
    end

    it 'formats payment without notes' do
      payment = quote.payments.create!(
        amount: 100.00,
        payment_date: Date.new(2025, 11, 29),
        payment_method: 'efectivo'
      )

      output = payment.to_s

      expect(output).to include('29/11/2025')
      expect(output).to include('100.00')
      expect(output).to include('Efectivo')
      expect(output).not_to include('-')
    end
  end

  describe 'table_name' do
    it 'uses budget_payments table' do
      expect(Budget::Payment.table_name).to eq('budget_payments')
    end
  end
end
