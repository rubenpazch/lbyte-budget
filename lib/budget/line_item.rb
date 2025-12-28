# frozen_string_literal: true

module Budget
  # Represents a single line item in a quote
  # Examples: lente (lens), montura (frame), tratamiento (treatment)
  class LineItem
    attr_accessor :description, :price, :category, :quantity

    CATEGORIES = %w[lente montura tratamiento accesorio servicio other].freeze

    def initialize(description:, price:, category: 'other', quantity: 1)
      @description = description
      @price = price.to_f
      @category = validate_category(category)
      @quantity = quantity.to_i
    end

    # Calculate subtotal (price * quantity)
    # @return [Float] Subtotal
    def subtotal
      @price * @quantity
    end

    # Get category in Spanish
    # @return [String] Category name in Spanish
    def category_name
      {
        'lente' => 'Lente',
        'montura' => 'Montura',
        'tratamiento' => 'Tratamiento',
        'accesorio' => 'Accesorio',
        'servicio' => 'Servicio',
        'other' => 'Otro'
      }[@category] || @category.capitalize
    end

    # Format line item for display
    # @return [String] Formatted line item
    def to_s
      if @quantity > 1
        "#{category_name} - #{@description} (#{@quantity} x $#{format('%.2f', @price)}) = $#{format('%.2f', subtotal)}"
      else
        "#{category_name} - #{@description}: $#{format('%.2f', @price)}"
      end
    end

    # Convert to hash
    # @return [Hash] Line item as hash
    def to_h
      {
        description: @description,
        price: @price,
        category: @category,
        quantity: @quantity,
        subtotal: subtotal
      }
    end

    private

    def validate_category(category)
      category = category.to_s
      CATEGORIES.include?(category) ? category : 'other'
    end
  end
end
