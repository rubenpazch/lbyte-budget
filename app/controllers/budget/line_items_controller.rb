# frozen_string_literal: true

module Budget
  # Controller for managing line items within quotes
  # Provides nested resource CRUD operations
  class LineItemsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    before_action :set_quote
    before_action :set_line_item, only: %i[show update destroy]

    # GET /budget/quotes/:quote_id/line_items
    def index
      @line_items = @quote.line_items.order(created_at: :asc)
      render json: @line_items.map { |item|
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
      }
    end

    # GET /budget/quotes/:quote_id/line_items/:id
    def show
      # @line_item set by before_action
      render json: {
        id: @line_item.id,
        description: @line_item.description,
        price: @line_item.price,
        category: @line_item.category,
        quantity: @line_item.quantity,
        created_at: @line_item.created_at,
        updated_at: @line_item.updated_at,
        category_name: @line_item.category_name,
        subtotal: @line_item.subtotal,
        quote_id: @line_item.budget_quote_id
      }
    end

    # POST /budget/quotes/:quote_id/line_items
    def create
      @line_item = @quote.line_items.new(line_item_params)

      if @line_item.save
        render json: {
          id: @line_item.id,
          description: @line_item.description,
          price: @line_item.price,
          category: @line_item.category,
          quantity: @line_item.quantity,
          created_at: @line_item.created_at,
          updated_at: @line_item.updated_at,
          category_name: @line_item.category_name,
          subtotal: @line_item.subtotal,
          quote_id: @line_item.budget_quote_id
        }, status: :created
      else
        render json: { errors: @line_item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /budget/quotes/:quote_id/line_items/:id
    def update
      if @line_item.update(line_item_params)
        render json: {
          id: @line_item.id,
          description: @line_item.description,
          price: @line_item.price,
          category: @line_item.category,
          quantity: @line_item.quantity,
          created_at: @line_item.created_at,
          updated_at: @line_item.updated_at,
          category_name: @line_item.category_name,
          subtotal: @line_item.subtotal,
          quote_id: @line_item.budget_quote_id
        }
      else
        render json: { errors: @line_item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /budget/quotes/:quote_id/line_items/:id
    def destroy
      @line_item.destroy
      head :no_content
    end

    private

    def set_quote
      @quote = Quote.find(params[:quote_id])
    end

    def set_line_item
      @line_item = @quote.line_items.find(params[:id])
    end

    def line_item_params
      params.require(:line_item).permit(:description, :price, :category, :quantity)
    end

    def not_found
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
