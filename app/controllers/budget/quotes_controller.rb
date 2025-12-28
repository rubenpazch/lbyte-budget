# frozen_string_literal: true

module Budget
  # Controller for managing budget quotes via REST API
  # Provides CRUD operations and summary endpoints for quotes
  class QuotesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    before_action :set_quote, only: %i[show update destroy]

    # GET /budget/quotes
    def index
      @quotes = Quote.includes(:line_items, :payments)
                     .order(created_at: :desc)

      render json: @quotes.map { |quote|
        {
          id: quote.id,
          customer_name: quote.customer_name,
          customer_contact: quote.customer_contact,
          quote_date: quote.quote_date,
          created_at: quote.created_at,
          line_items_count: quote.line_items.size,
          payments_count: quote.payments.size,
          totals: {
            total: quote.total,
            total_paid: quote.total_paid,
            remaining_balance: quote.remaining_balance,
            fully_paid: quote.fully_paid?
          }
        }
      }
    end

    # GET /budget/quotes/:id
    def show
      # @quote set by before_action
      render json: {
        id: @quote.id,
        customer_name: @quote.customer_name,
        customer_contact: @quote.customer_contact,
        notes: @quote.notes,
        quote_date: @quote.quote_date,
        created_at: @quote.created_at,
        updated_at: @quote.updated_at,
        line_items: @quote.line_items.map do |item|
          {
            id: item.id,
            description: item.description,
            price: item.price,
            category: item.category,
            quantity: item.quantity,
            created_at: item.created_at,
            category_name: item.category_name,
            subtotal: item.subtotal
          }
        end,
        payments: @quote.payments.ordered.map do |payment|
          {
            id: payment.id,
            amount: payment.amount,
            payment_date: payment.payment_date,
            payment_method: payment.payment_method,
            notes: payment.notes,
            created_at: payment.created_at,
            payment_method_name: payment.payment_method_name
          }
        end,
        totals: {
          total: @quote.total,
          total_paid: @quote.total_paid,
          remaining_balance: @quote.remaining_balance,
          fully_paid: @quote.fully_paid?
        },
        category_breakdown: @quote.category_breakdown
      }
    end

    # POST /budget/quotes
    def create
      @quote = Quote.new(quote_params)

      if @quote.save
        render json: {
          id: @quote.id,
          customer_name: @quote.customer_name,
          customer_contact: @quote.customer_contact,
          notes: @quote.notes,
          quote_date: @quote.quote_date,
          created_at: @quote.created_at,
          updated_at: @quote.updated_at,
          line_items: [],
          payments: [],
          totals: {
            total: 0.0,
            total_paid: 0.0,
            remaining_balance: 0.0,
            fully_paid: false
          },
          category_breakdown: {}
        }, status: :created
      else
        render json: { errors: @quote.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /budget/quotes/:id
    def update
      if @quote.update(quote_params)
        render json: {
          id: @quote.id,
          customer_name: @quote.customer_name,
          customer_contact: @quote.customer_contact,
          notes: @quote.notes,
          quote_date: @quote.quote_date,
          created_at: @quote.created_at,
          updated_at: @quote.updated_at,
          line_items: @quote.line_items.map do |item|
            {
              id: item.id,
              description: item.description,
              price: item.price,
              category: item.category,
              quantity: item.quantity,
              created_at: item.created_at,
              category_name: item.category_name,
              subtotal: item.subtotal
            }
          end,
          payments: @quote.payments.ordered.map do |payment|
            {
              id: payment.id,
              amount: payment.amount,
              payment_date: payment.payment_date,
              payment_method: payment.payment_method,
              notes: payment.notes,
              created_at: payment.created_at,
              payment_method_name: payment.payment_method_name
            }
          end,
          totals: {
            total: @quote.total,
            total_paid: @quote.total_paid,
            remaining_balance: @quote.remaining_balance,
            fully_paid: @quote.fully_paid?
          },
          category_breakdown: @quote.category_breakdown
        }
      else
        render json: { errors: @quote.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /budget/quotes/:id
    def destroy
      @quote.destroy
      head :no_content
    end

    # GET /budget/quotes/:id/summary
    def summary
      @quote = Quote.find(params[:id])
      render json: @quote.summary
    end

    private

    def set_quote
      @quote = Quote.includes(:line_items, :payments).find(params[:id])
    end

    def quote_params
      params.require(:quote).permit(:customer_name, :customer_contact, :quote_date, :notes)
    end

    def not_found
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
