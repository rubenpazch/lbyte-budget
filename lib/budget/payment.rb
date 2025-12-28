# frozen_string_literal: true

module Budget
  # Represents a payment made towards a quote
  # Can be initial payment (adelanto) or subsequent payments
  class Payment
    attr_accessor :amount, :payment_date, :payment_method, :notes

    PAYMENT_METHODS = %w[efectivo tarjeta transferencia cheque other].freeze

    def initialize(amount:, payment_date: nil, payment_method: 'efectivo', notes: nil)
      @amount = amount.to_f
      @payment_date = payment_date || Time.now
      @payment_method = validate_payment_method(payment_method)
      @notes = notes
    end

    # Get payment method in Spanish
    # @return [String] Payment method in Spanish
    def payment_method_name
      {
        'efectivo' => 'Efectivo',
        'tarjeta' => 'Tarjeta',
        'transferencia' => 'Transferencia',
        'cheque' => 'Cheque',
        'other' => 'Otro'
      }[@payment_method] || @payment_method.capitalize
    end

    # Format payment for display
    # @return [String] Formatted payment
    def to_s
      output = "$#{format('%.2f', @amount)} - #{payment_method_name} (#{@payment_date.strftime('%d/%m/%Y')})"
      output += " - #{@notes}" if @notes
      output
    end

    # Convert to hash
    # @return [Hash] Payment as hash
    def to_h
      {
        amount: @amount,
        payment_date: @payment_date,
        payment_method: @payment_method,
        notes: @notes
      }
    end

    private

    def validate_payment_method(method)
      method = method.to_s.downcase
      PAYMENT_METHODS.include?(method) ? method : 'other'
    end
  end
end
