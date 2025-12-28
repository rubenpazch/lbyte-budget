# frozen_string_literal: true

module Budget
  # ActiveRecord model for budget quotes
  # Manages quotes with line items and payments
  class Quote < ActiveRecord::Base
    self.table_name = 'budget_quotes'

    # External associations (optional - can be defined in host application)
    # Uncomment this line in your host app's Budget::Quote decorator if needed:
    # belongs_to :prescription, optional: true

    # Associations
    has_many :line_items, class_name: 'Budget::LineItem', foreign_key: 'budget_quote_id', dependent: :destroy
    has_many :payments, class_name: 'Budget::Payment', foreign_key: 'budget_quote_id', dependent: :destroy

    # Validations
    validates :customer_name, presence: true
    validates :quote_date, presence: true

    # Callbacks
    before_validation :set_quote_date, on: :create

    # Scopes
    scope :recent, -> { order(created_at: :desc) }
    scope :by_customer, ->(name) { where('customer_name LIKE ?', "%#{name}%") }
    scope :pending, lambda {
      # Find quotes where payments don't cover all line items
      # This requires calculating totals in Ruby since we don't have a total column
      all.reject(&:fully_paid?)
    }

    # Calculate total price of all line items
    # @return [Float] Total price
    def total
      line_items.sum(&:subtotal)
    end

    # Calculate total amount paid so far
    # @return [Float] Total paid
    def total_paid
      payments.sum(:amount)
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
      payments.order(:payment_date).first
    end

    # Get breakdown by category
    # @return [Hash] Category totals
    def category_breakdown
      breakdown = Hash.new(0)
      line_items.each do |item|
        breakdown[item.category.to_sym] += item.subtotal
      end
      breakdown
    end

    # Generate a summary of the quote
    # @return [Hash] Quote summary
    def summary
      {
        id: id,
        customer_name: customer_name,
        customer_contact: customer_contact,
        date: quote_date,
        line_items_count: line_items.count,
        total: total,
        total_paid: total_paid,
        remaining_balance: remaining_balance,
        fully_paid: fully_paid?,
        category_breakdown: category_breakdown,
        payments_count: payments.count
      }
    end

    # Format quote for display
    # @return [String] Formatted quote
    def to_s
      output = []
      output << ('=' * 60)
      output << "PRESUPUESTO ##{id}"
      output << ('=' * 60)
      output << "Cliente: #{customer_name}"
      output << "Contacto: #{customer_contact}" if customer_contact
      output << "Fecha: #{quote_date.strftime('%d/%m/%Y')}"
      output << "Notas: #{notes}" if notes
      output << ''
      output << 'DETALLE:'
      output << ('-' * 60)

      line_items.each_with_index do |item, index|
        output << "#{index + 1}. #{item}"
      end

      output << ('-' * 60)
      output << "TOTAL: $#{format('%.2f', total)}"
      output << ''

      if payments.any?
        output << 'PAGOS:'
        output << ('-' * 60)
        payments.order(:payment_date).each_with_index do |payment, index|
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

    # Add a line item to the quote
    def add_line_item(description:, price:, category: 'other', quantity: 1)
      line_items.create!(
        description: description,
        price: price,
        category: category,
        quantity: quantity
      )
    end

    # Add a payment (adelanto or subsequent payment)
    def add_payment(amount:, payment_date: nil, payment_method: 'efectivo', notes: nil)
      payments.create!(
        amount: amount,
        payment_date: payment_date || Time.current,
        payment_method: payment_method,
        notes: notes
      )
    end

    private

    def set_quote_date
      self.quote_date ||= Time.current
    end
  end
end
