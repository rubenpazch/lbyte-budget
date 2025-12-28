# frozen_string_literal: true

module Budget
  # Represents a quote/budget for eyeglasses purchase
  # Manages line items (lentes, montura, tratamiento) and payments
  class Quote
    attr_accessor :id, :customer_name, :customer_contact, :date, :notes
    attr_reader :line_items, :payments

    def initialize(customer_name:, id: nil, customer_contact: nil, date: nil, notes: nil)
      @id = id || generate_id
      @customer_name = customer_name
      @customer_contact = customer_contact
      @date = date || Time.now
      @notes = notes
      @line_items = []
      @payments = []
    end

    # Add a line item to the quote
    # @param description [String] Item description (e.g., "Lente progresivo", "Montura metal")
    # @param price [Float] Item price
    # @param category [Symbol] :lente, :montura, :tratamiento, :other
    def add_line_item(description:, price:, category: :other, quantity: 1)
      # Convert symbol to string for consistency
      category = category.to_s if category.is_a?(Symbol)
      line_item = LineItem.new(
        description: description,
        price: price,
        category: category,
        quantity: quantity
      )
      @line_items << line_item
      line_item
    end

    # Remove a line item by index
    def remove_line_item(index)
      @line_items.delete_at(index)
    end

    # Add a payment (adelanto or subsequent payment)
    # @param amount [Float] Payment amount
    # @param payment_date [Time] When payment was made
    # @param payment_method [String] How payment was made (efectivo, tarjeta, transferencia)
    # @param notes [String] Additional notes about payment
    def add_payment(amount:, payment_date: nil, payment_method: 'efectivo', notes: nil)
      payment = Payment.new(
        amount: amount,
        payment_date: payment_date || Time.now,
        payment_method: payment_method,
        notes: notes
      )
      @payments << payment
      payment
    end

    # Calculate total price of all line items
    # @return [Float] Total price
    def total
      @line_items.sum(&:subtotal)
    end

    # Calculate total amount paid so far
    # @return [Float] Total paid
    def total_paid
      @payments.sum(&:amount)
    end

    # Calculate remaining balance to be paid
    # @return [Float] Remaining amount
    def remaining_balance
      total - total_paid
    end

    # Check if quote is fully paid
    # @return [Boolean]
    def fully_paid?
      remaining_balance <= 0
    end

    # Get the initial payment (adelanto)
    # @return [Payment, nil] First payment or nil if no payments
    def initial_payment
      @payments.first
    end

    # Get breakdown by category
    # @return [Hash] Category totals
    def category_breakdown
      breakdown = Hash.new(0)
      @line_items.each do |item|
        breakdown[item.category] += item.subtotal
      end
      breakdown
    end

    # Generate a summary of the quote
    # @return [Hash] Quote summary
    def summary
      {
        id: @id,
        customer_name: @customer_name,
        customer_contact: @customer_contact,
        date: @date,
        line_items_count: @line_items.count,
        total: total,
        total_paid: total_paid,
        remaining_balance: remaining_balance,
        fully_paid: fully_paid?,
        category_breakdown: category_breakdown,
        payments_count: @payments.count
      }
    end

    # Format quote for display
    # @return [String] Formatted quote
    def to_s
      output = []
      output << ('=' * 60)
      output << "PRESUPUESTO ##{@id}"
      output << ('=' * 60)
      output << "Cliente: #{@customer_name}"
      output << "Contacto: #{@customer_contact}" if @customer_contact
      output << "Fecha: #{@date.strftime('%d/%m/%Y')}"
      output << "Notas: #{@notes}" if @notes
      output << ''
      output << 'DETALLE:'
      output << ('-' * 60)

      @line_items.each_with_index do |item, index|
        output << "#{index + 1}. #{item}"
      end

      output << ('-' * 60)
      output << "TOTAL: $#{format('%.2f', total)}"
      output << ''

      if @payments.any?
        output << 'PAGOS:'
        output << ('-' * 60)
        @payments.each_with_index do |payment, index|
          output << "#{index + 1}. #{payment}"
        end
        output << ('-' * 60)
        output << "Total Pagado: $#{format('%.2f', total_paid)}"
      end

      output << ''
      output << "SALDO PENDIENTE: $#{format('%.2f', remaining_balance)}"
      output << "Estado: #{fully_paid? ? 'PAGADO COMPLETO' : 'PENDIENTE'}"
      output << ('=' * 60)

      output.join("\n")
    end

    private

    def generate_id
      "Q#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end
  end
end
