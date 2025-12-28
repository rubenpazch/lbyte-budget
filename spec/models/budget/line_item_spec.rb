# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::LineItem, type: :model do
  let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

  describe 'associations' do
    it { expect(described_class.reflect_on_association(:quote).macro).to eq(:belongs_to) }

    it 'belongs to a quote' do
      line_item = quote.line_items.create!(description: 'Test', price: 100, category: 'lente')
      expect(line_item.quote).to eq(quote)
    end
  end

  describe 'validations' do
    it 'requires description' do
      item = Budget::LineItem.new(price: 100, category: 'lente', budget_quote_id: quote.id)
      expect(item).not_to be_valid
      expect(item.errors[:description]).to include("can't be blank")
    end

    it 'requires price' do
      item = Budget::LineItem.new(description: 'Test', category: 'lente', budget_quote_id: quote.id)
      expect(item).not_to be_valid
      expect(item.errors[:price]).to include("can't be blank")
    end

    it 'requires price to be greater than 0' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 0,
        category: 'lente',
        budget_quote_id: quote.id
      )
      expect(item).not_to be_valid
      expect(item.errors[:price]).to include('must be greater than 0')
    end

    it 'accepts valid price' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 0.01,
        category: 'lente',
        budget_quote_id: quote.id
      )
      expect(item).to be_valid
    end

    it 'sets default category to other when nil' do
      item = Budget::LineItem.new(description: 'Test', price: 100, budget_quote_id: quote.id)
      item.category = nil
      item.valid?
      expect(item.category).to eq('other')
    end

    it 'requires quantity' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 100,
        category: 'lente',
        budget_quote_id: quote.id
      )
      item.quantity = nil
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("can't be blank")
    end

    it 'requires quantity to be greater than 0' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 100,
        category: 'lente',
        quantity: 0,
        budget_quote_id: quote.id
      )
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include('must be greater than 0')
    end

    it 'is valid with all required attributes' do
      item = Budget::LineItem.new(
        description: 'Test Item',
        price: 100,
        category: 'lente',
        quantity: 1,
        budget_quote_id: quote.id
      )
      expect(item).to be_valid
    end
  end

  describe 'callbacks' do
    it 'sets default quantity to 1 if not provided' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 100,
        category: 'lente',
        budget_quote_id: quote.id
      )
      item.valid?
      expect(item.quantity).to eq(1)
    end

    it 'does not override quantity if already set' do
      item = Budget::LineItem.create!(
        description: 'Test',
        price: 100,
        category: 'lente',
        quantity: 5,
        budget_quote_id: quote.id
      )
      expect(item.quantity).to eq(5)
    end

    it 'sets default category to other if not provided' do
      item = Budget::LineItem.new(
        description: 'Test',
        price: 100,
        budget_quote_id: quote.id
      )
      item.valid?
      expect(item.category).to eq('other')
    end
  end

  describe 'CATEGORIES constant' do
    it 'defines all available categories' do
      expect(Budget::LineItem::CATEGORIES).to eq(%w[lente montura tratamiento accesorio servicio other])
    end
  end

  describe '#subtotal' do
    it 'calculates price * quantity' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 50,
        quantity: 3,
        category: 'lente'
      )
      expect(item.subtotal).to eq(150)
    end

    it 'returns price when quantity is 1' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 75.50,
        quantity: 1,
        category: 'lente'
      )
      expect(item.subtotal).to eq(75.50)
    end

    it 'handles decimal prices correctly' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 33.33,
        quantity: 3,
        category: 'lente'
      )
      expect(item.subtotal).to eq(99.99)
    end
  end

  describe '#category_name' do
    it 'returns Spanish name for lente' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'lente'
      )
      expect(item.category_name).to eq('Lente')
    end

    it 'returns Spanish name for montura' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'montura'
      )
      expect(item.category_name).to eq('Montura')
    end

    it 'returns Spanish name for tratamiento' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'tratamiento'
      )
      expect(item.category_name).to eq('Tratamiento')
    end

    it 'returns Spanish name for accesorio' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'accesorio'
      )
      expect(item.category_name).to eq('Accesorio')
    end

    it 'returns Spanish name for servicio' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'servicio'
      )
      expect(item.category_name).to eq('Servicio')
    end

    it 'returns Spanish name for other' do
      item = quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'other'
      )
      expect(item.category_name).to eq('Otro')
    end

    it 'returns capitalized category for unknown categories' do
      item = quote.line_items.build(
        description: 'Test',
        price: 100,
        category: 'custom'
      )
      expect(item.category_name).to eq('Custom')
    end
  end

  describe '#to_s' do
    it 'formats line item with all details' do
      item = quote.line_items.create!(
        description: 'Lentes progresivos',
        price: 150.00,
        quantity: 2,
        category: 'lente'
      )

      output = item.to_s

      expect(output).to include('Lentes progresivos')
      expect(output).to include('Lente')
      expect(output).to include('150.00')
      expect(output).to include('(2 x')
      expect(output).to include('300.00')
    end

    it 'formats line item with quantity 1' do
      item = quote.line_items.create!(
        description: 'Montura',
        price: 80.00,
        quantity: 1,
        category: 'montura'
      )

      output = item.to_s

      expect(output).to include('Montura')
      expect(output).to include('$80.00')
      expect(output).not_to include(' x ')
    end
  end

  describe 'table_name' do
    it 'uses budget_line_items table' do
      expect(Budget::LineItem.table_name).to eq('budget_line_items')
    end
  end
end
