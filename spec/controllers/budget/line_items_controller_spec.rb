# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::LineItemsController, type: :controller do
  render_views
  routes { Budget::Engine.routes }

  let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index, params: { quote_id: quote.id }, format: :json
      expect(response).to be_successful
    end

    it 'returns all line items for the quote' do
      quote.line_items.create!(description: 'Item 1', price: 100, category: 'lente')
      quote.line_items.create!(description: 'Item 2', price: 50, category: 'montura')

      get :index, params: { quote_id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'includes line item details' do
      quote.line_items.create!(
        description: 'Lentes progresivos',
        price: 150,
        quantity: 2,
        category: 'lente'
      )

      get :index, params: { quote_id: quote.id }, format: :json

      json = JSON.parse(response.body).first
      expect(json['description']).to eq('Lentes progresivos')
      expect(json['price']).to eq('150.0')
      expect(json['quantity']).to eq(2)
      expect(json['category']).to eq('lente')
      expect(json['subtotal']).to eq('300.0')
    end

    it 'returns 404 for non-existent quote' do
      get :index, params: { quote_id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let(:line_item) do
      quote.line_items.create!(
        description: 'Lentes',
        price: 150,
        quantity: 1,
        category: 'lente'
      )
    end

    it 'returns a successful response' do
      get :show, params: { quote_id: quote.id, id: line_item.id }, format: :json
      expect(response).to be_successful
    end

    it 'returns line item details' do
      get :show, params: { quote_id: quote.id, id: line_item.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['id']).to eq(line_item.id)
      expect(json['description']).to eq('Lentes')
      expect(json['price']).to eq('150.0')
      expect(json['category']).to eq('lente')
      expect(json['subtotal']).to eq('150.0')
    end

    it 'returns 404 for non-existent line item' do
      get :show, params: { quote_id: quote.id, id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for line item from different quote' do
      other_quote = Budget::Quote.create!(customer_name: 'Other', quote_date: Date.today)
      other_item = other_quote.line_items.create!(description: 'Test', price: 100, category: 'lente')

      get :show, params: { quote_id: quote.id, id: other_item.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a new line item' do
      expect do
        post :create, params: {
          quote_id: quote.id,
          line_item: {
            description: 'Lentes progresivos',
            price: 150,
            category: 'lente',
            quantity: 1
          }
        }, format: :json
      end.to change(Budget::LineItem, :count).by(1)
    end

    it 'associates line item with quote' do
      post :create, params: {
        quote_id: quote.id,
        line_item: {
          description: 'Lentes',
          price: 150,
          category: 'lente'
        }
      }, format: :json

      line_item = Budget::LineItem.last
      expect(line_item.quote).to eq(quote)
    end

    it 'returns created status' do
      post :create, params: {
        quote_id: quote.id,
        line_item: {
          description: 'Lentes',
          price: 150,
          category: 'lente'
        }
      }, format: :json

      expect(response).to have_http_status(:created)
    end

    it 'returns the created line item' do
      post :create, params: {
        quote_id: quote.id,
        line_item: {
          description: 'Lentes progresivos',
          price: 150.50,
          category: 'lente',
          quantity: 2
        }
      }, format: :json

      json = JSON.parse(response.body)
      expect(json['description']).to eq('Lentes progresivos')
      expect(json['price']).to eq('150.5')
      expect(json['quantity']).to eq(2)
      expect(json['subtotal']).to eq('301.0')
    end

    it 'returns errors for invalid line item' do
      post :create, params: {
        quote_id: quote.id,
        line_item: {
          price: 150
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'returns 404 for non-existent quote' do
      post :create, params: {
        quote_id: 99_999,
        line_item: {
          description: 'Test',
          price: 100,
          category: 'lente'
        }
      }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #update' do
    let(:line_item) do
      quote.line_items.create!(
        description: 'Original',
        price: 100,
        category: 'lente'
      )
    end

    it 'updates the line item' do
      patch :update, params: {
        quote_id: quote.id,
        id: line_item.id,
        line_item: {
          description: 'Updated',
          price: 200,
          quantity: 3
        }
      }, format: :json

      line_item.reload
      expect(line_item.description).to eq('Updated')
      expect(line_item.price).to eq(200)
      expect(line_item.quantity).to eq(3)
    end

    it 'returns the updated line item' do
      patch :update, params: {
        quote_id: quote.id,
        id: line_item.id,
        line_item: {
          description: 'Updated'
        }
      }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['description']).to eq('Updated')
    end

    it 'returns errors for invalid update' do
      patch :update, params: {
        quote_id: quote.id,
        id: line_item.id,
        line_item: {
          price: -10
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for non-existent line item' do
      patch :update, params: {
        quote_id: quote.id,
        id: 99_999,
        line_item: { description: 'Test' }
      }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:line_item) do
      quote.line_items.create!(
        description: 'Test',
        price: 100,
        category: 'lente'
      )
    end

    it 'destroys the line item' do
      expect do
        delete :destroy, params: { quote_id: quote.id, id: line_item.id }, format: :json
      end.to change(Budget::LineItem, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { quote_id: quote.id, id: line_item.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent line item' do
      delete :destroy, params: { quote_id: quote.id, id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
