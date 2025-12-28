# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::Engine do
  describe 'engine configuration' do
    it 'is a Rails::Engine' do
      expect(Budget::Engine.superclass).to eq(Rails::Engine)
    end

    it 'isolates namespace' do
      expect(Budget::Engine.isolated?).to be true
    end

    it 'has the correct engine name' do
      expect(Budget::Engine.engine_name).to eq('budget')
    end
  end

  describe 'routes' do
    it 'defines quotes routes' do
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quotes_path)
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quote_path)
    end

    it 'defines nested line_items routes' do
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quote_line_items_path)
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quote_line_item_path)
    end

    it 'defines nested payments routes' do
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quote_payments_path)
      expect(Budget::Engine.routes.url_helpers).to respond_to(:quote_payment_path)
    end

    it 'defines summary route' do
      expect(Budget::Engine.routes.url_helpers).to respond_to(:summary_quote_path)
    end
  end
end
