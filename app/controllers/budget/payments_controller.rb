# frozen_string_literal: true

module Budget
  # Controller for managing payments within quotes
  # Provides nested resource CRUD operations for payment tracking
  class PaymentsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    before_action :set_quote
    before_action :set_payment, only: %i[show update destroy]

    # GET /budget/quotes/:quote_id/payments
    def index
      @payments = @quote.payments.ordered
      render json: @payments.map { |payment|
        {
          id: payment.id,
          amount: payment.amount,
          payment_date: payment.payment_date,
          payment_method: payment.payment_method,
          notes: payment.notes,
          created_at: payment.created_at,
          payment_method_name: payment.payment_method_name
        }
      }
    end

    # GET /budget/quotes/:quote_id/payments/:id
    def show
      # @payment set by before_action
      render json: {
        id: @payment.id,
        amount: @payment.amount,
        payment_date: @payment.payment_date,
        payment_method: @payment.payment_method,
        notes: @payment.notes,
        created_at: @payment.created_at,
        updated_at: @payment.updated_at,
        payment_method_name: @payment.payment_method_name,
        quote_id: @payment.budget_quote_id
      }
    end

    # POST /budget/quotes/:quote_id/payments
    def create
      @payment = @quote.payments.new(payment_params)

      if @payment.save
        render json: {
          id: @payment.id,
          amount: @payment.amount,
          payment_date: @payment.payment_date,
          payment_method: @payment.payment_method,
          notes: @payment.notes,
          created_at: @payment.created_at,
          updated_at: @payment.updated_at,
          payment_method_name: @payment.payment_method_name,
          quote_id: @payment.budget_quote_id
        }, status: :created
      else
        render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /budget/quotes/:quote_id/payments/:id
    def update
      if @payment.update(payment_params)
        render json: {
          id: @payment.id,
          amount: @payment.amount,
          payment_date: @payment.payment_date,
          payment_method: @payment.payment_method,
          notes: @payment.notes,
          created_at: @payment.created_at,
          updated_at: @payment.updated_at,
          payment_method_name: @payment.payment_method_name,
          quote_id: @payment.budget_quote_id
        }
      else
        render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /budget/quotes/:quote_id/payments/:id
    def destroy
      @payment.destroy
      head :no_content
    end

    private

    def set_quote
      @quote = Quote.find(params[:quote_id])
    end

    def set_payment
      @payment = @quote.payments.find(params[:id])
    end

    def payment_params
      params.require(:payment).permit(:amount, :payment_date, :payment_method, :notes)
    end

    def not_found
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
