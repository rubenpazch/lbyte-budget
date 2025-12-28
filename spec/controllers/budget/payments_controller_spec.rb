# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget::PaymentsController, type: :controller do
  render_views
  routes { Budget::Engine.routes }

  let(:quote) { Budget::Quote.create!(customer_name: 'John Doe', quote_date: Date.today) }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index, params: { quote_id: quote.id }, format: :json
      expect(response).to be_successful
    end

    it 'returns all payments for the quote' do
      quote.payments.create!(amount: 100, payment_date: Date.today, payment_method: 'efectivo')
      quote.payments.create!(amount: 50, payment_date: Date.today, payment_method: 'tarjeta')

      get :index, params: { quote_id: quote.id }, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'includes payment details' do
      quote.payments.create!(
        amount: 150,
        payment_date: Date.new(2025, 11, 29),
        payment_method: 'tarjeta',
        notes: 'Adelanto'
      )

      get :index, params: { quote_id: quote.id }, format: :json

      json = JSON.parse(response.body).first
      expect(json['amount']).to eq('150.0')
      expect(json['payment_method']).to eq('tarjeta')
      expect(json['notes']).to eq('Adelanto')
    end

    it 'returns 404 for non-existent quote' do
      get :index, params: { quote_id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let(:payment) do
      quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )
    end

    it 'returns a successful response' do
      get :show, params: { quote_id: quote.id, id: payment.id }, format: :json
      expect(response).to be_successful
    end

    it 'returns payment details' do
      get :show, params: { quote_id: quote.id, id: payment.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['id']).to eq(payment.id)
      expect(json['amount']).to eq('100.0')
      expect(json['payment_method']).to eq('efectivo')
    end

    it 'returns 404 for non-existent payment' do
      get :show, params: { quote_id: quote.id, id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for payment from different quote' do
      other_quote = Budget::Quote.create!(customer_name: 'Other', quote_date: Date.today)
      other_payment = other_quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )

      get :show, params: { quote_id: quote.id, id: other_payment.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a new payment' do
      expect do
        post :create, params: {
          quote_id: quote.id,
          payment: {
            amount: 150,
            payment_method: 'tarjeta',
            notes: 'Adelanto'
          }
        }, format: :json
      end.to change(Budget::Payment, :count).by(1)
    end

    it 'associates payment with quote' do
      post :create, params: {
        quote_id: quote.id,
        payment: {
          amount: 100,
          payment_method: 'efectivo'
        }
      }, format: :json

      payment = Budget::Payment.last
      expect(payment.quote).to eq(quote)
    end

    it 'returns created status' do
      post :create, params: {
        quote_id: quote.id,
        payment: {
          amount: 100,
          payment_method: 'efectivo'
        }
      }, format: :json

      expect(response).to have_http_status(:created)
    end

    it 'returns the created payment' do
      post :create, params: {
        quote_id: quote.id,
        payment: {
          amount: 150.50,
          payment_method: 'tarjeta',
          notes: 'Pago inicial'
        }
      }, format: :json

      json = JSON.parse(response.body)
      expect(json['amount']).to eq('150.5')
      expect(json['payment_method']).to eq('tarjeta')
      expect(json['notes']).to eq('Pago inicial')
    end

    it 'sets payment_date to today if not provided' do
      post :create, params: {
        quote_id: quote.id,
        payment: {
          amount: 100,
          payment_method: 'efectivo'
        }
      }, format: :json

      payment = Budget::Payment.last
      expect(payment.payment_date).to eq(Date.today)
    end

    it 'accepts custom payment_date' do
      custom_date = Date.new(2025, 1, 15)
      post :create, params: {
        quote_id: quote.id,
        payment: {
          amount: 100,
          payment_date: custom_date,
          payment_method: 'efectivo'
        }
      }, format: :json

      payment = Budget::Payment.last
      expect(payment.payment_date).to eq(custom_date)
    end

    it 'returns errors for invalid payment' do
      post :create, params: {
        quote_id: quote.id,
        payment: {
          payment_method: 'efectivo'
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'returns 404 for non-existent quote' do
      post :create, params: {
        quote_id: 99_999,
        payment: {
          amount: 100,
          payment_method: 'efectivo'
        }
      }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #update' do
    let(:payment) do
      quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )
    end

    it 'updates the payment' do
      new_date = Date.new(2025, 12, 1)
      patch :update, params: {
        quote_id: quote.id,
        id: payment.id,
        payment: {
          amount: 200,
          payment_date: new_date,
          payment_method: 'tarjeta',
          notes: 'Updated'
        }
      }, format: :json

      payment.reload
      expect(payment.amount).to eq(200)
      expect(payment.payment_date).to eq(new_date)
      expect(payment.payment_method).to eq('tarjeta')
      expect(payment.notes).to eq('Updated')
    end

    it 'returns the updated payment' do
      patch :update, params: {
        quote_id: quote.id,
        id: payment.id,
        payment: {
          notes: 'Pago completo'
        }
      }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['notes']).to eq('Pago completo')
    end

    it 'returns errors for invalid update' do
      patch :update, params: {
        quote_id: quote.id,
        id: payment.id,
        payment: {
          amount: -50
        }
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for non-existent payment' do
      patch :update, params: {
        quote_id: quote.id,
        id: 99_999,
        payment: { amount: 100 }
      }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:payment) do
      quote.payments.create!(
        amount: 100,
        payment_date: Date.today,
        payment_method: 'efectivo'
      )
    end

    it 'destroys the payment' do
      expect do
        delete :destroy, params: { quote_id: quote.id, id: payment.id }, format: :json
      end.to change(Budget::Payment, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { quote_id: quote.id, id: payment.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent payment' do
      delete :destroy, params: { quote_id: quote.id, id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
