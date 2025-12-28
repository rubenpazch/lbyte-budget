# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::QuotesController, type: :controller do
  render_views
  routes { Budget::Engine.routes }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index, format: :json
      expect(response).to be_successful
    end

    it 'returns all quotes' do
      Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      Budget::Quote.create!(customer_name: 'Jane', quote_date: Date.today)

      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'returns quotes in descending order by created_at' do
      old_quote = Budget::Quote.create!(customer_name: 'Old', quote_date: Date.today - 5.days)
      new_quote = Budget::Quote.create!(customer_name: 'New', quote_date: Date.today)

      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json.first['id']).to eq(new_quote.id)
      expect(json.last['id']).to eq(old_quote.id)
    end

    it 'includes quote summary fields' do
      quote = Budget::Quote.create!(customer_name: 'John', quote_date: Date.today)
      quote.line_items.create!(description: 'Test', price: 100, category: 'lente')
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'efectivo')

      get :index, format: :json

      json = JSON.parse(response.body).first
      expect(json['customer_name']).to eq('John')
      expect(json['line_items_count']).to eq(1)
      expect(json['payments_count']).to eq(1)
      expect(json['totals']['total']).to eq('100.0')
      expect(json['totals']['total_paid']).to eq('50.0')
      expect(json['totals']['remaining_balance']).to eq('50.0')
      expect(json['totals']['fully_paid']).to be false
    end
  end

  describe 'GET #show' do
    let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', customer_contact: '555-1234', quote_date: Date.today) }

    it 'returns a successful response' do
      get :show, params: { id: quote.id }, format: :json
      expect(response).to be_successful
    end

    it 'returns quote details' do
      get :show, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['id']).to eq(quote.id)
      expect(json['customer_name']).to eq('John Doe')
      expect(json['customer_contact']).to eq('555-1234')
    end

    it 'includes line items' do
      quote.line_items.create!(description: 'Lentes', price: 150, category: 'lente')
      quote.line_items.create!(description: 'Montura', price: 80, category: 'montura')

      get :show, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['line_items'].length).to eq(2)
      expect(json['line_items'].first['description']).to eq('Lentes')
    end

    it 'includes payments' do
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')

      get :show, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['payments'].length).to eq(1)
      expect(json['payments'].first['amount']).to eq('100.0')
    end

    it 'includes totals' do
      quote.line_items.create!(description: 'Test', price: 200, category: 'lente')
      quote.payments.create!(amount: 75, payment_date: Date.today, payment_method: 'efectivo')

      get :show, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['totals']['total']).to eq('200.0')
      expect(json['totals']['total_paid']).to eq('75.0')
      expect(json['totals']['remaining_balance']).to eq('125.0')
      expect(json['totals']['fully_paid']).to be false
    end

    it 'includes category breakdown' do
      quote.line_items.create!(description: 'Lentes', price: 150, category: 'lente')
      quote.line_items.create!(description: 'Montura', price: 80, category: 'montura')

      get :show, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['category_breakdown']['lente']).to eq('150.0')
      expect(json['category_breakdown']['montura']).to eq('80.0')
    end

    it 'returns 404 for non-existent quote' do
      get :show, params: { id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a new quote' do
      expect do
        post :create, params: {
          quote: {
            customer_name: 'María González',
            customer_contact: '555-1234'
          }
        }, format: :json
      end.to change(Budget::Quote, :count).by(1)
    end

    it 'returns created status' do
      post :create, params: {
        quote: {
          customer_name: 'María González',
          customer_contact: '555-1234'
        }
      }, format: :json

      expect(response).to have_http_status(:created)
    end

    it 'returns the created quote' do
      post :create, params: {
        quote: {
          customer_name: 'María González',
          customer_contact: '555-1234',
          notes: 'Test quote'
        }
      }, format: :json

      json = JSON.parse(response.body)
      expect(json['customer_name']).to eq('María González')
      expect(json['customer_contact']).to eq('555-1234')
      expect(json['notes']).to eq('Test quote')
    end

    it 'returns errors for invalid quote' do
      post :create, params: {
        quote: {
          customer_contact: '555-1234'
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe 'PATCH #update' do
    let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

    it 'updates the quote' do
      patch :update, params: {
        id: quote.id,
        quote: {
          customer_name: 'Jane Doe',
          customer_contact: '555-9999'
        }
      }, format: :json

      quote.reload
      expect(quote.customer_name).to eq('Jane Doe')
      expect(quote.customer_contact).to eq('555-9999')
    end

    it 'returns the updated quote' do
      patch :update, params: {
        id: quote.id,
        quote: {
          customer_name: 'Jane Doe'
        }
      }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['customer_name']).to eq('Jane Doe')
    end

    it 'returns errors for invalid update' do
      patch :update, params: {
        id: quote.id,
        quote: {
          customer_name: ''
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for non-existent quote' do
      patch :update, params: {
        id: 99_999,
        quote: { customer_name: 'Test' }
      }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

    it 'destroys the quote' do
      expect do
        delete :destroy, params: { id: quote.id }, format: :json
      end.to change(Budget::Quote, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { id: quote.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent quote' do
      delete :destroy, params: { id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #summary' do
    let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

    it 'returns quote summary' do
      quote.line_items.create!(description: 'Test', price: 100, category: 'lente')
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'efectivo')

      get :summary, params: { id: quote.id }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['customer_name']).to eq('John Doe')
      expect(json['total'].to_f).to eq(100.0)
      expect(json['total_paid'].to_f).to eq(50.0)
      expect(json['remaining_balance'].to_f).to eq(50.0)
      expect(json['fully_paid']).to be false
    end

    it 'includes category breakdown' do
      quote.line_items.create!(description: 'Lentes', price: 150, category: 'lente')
      quote.line_items.create!(description: 'Montura', price: 80, category: 'montura')

      get :summary, params: { id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['category_breakdown']['lente'].to_f).to eq(150.0)
      expect(json['category_breakdown']['montura'].to_f).to eq(80.0)
    end
  end
end
