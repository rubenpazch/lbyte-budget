# frozen_string_literal: true

class CreateBudgetLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :budget_line_items do |t|
      t.references :budget_quote, null: false, foreign_key: true, index: true
      t.string :description, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.string :category, default: 'other'
      t.integer :quantity, default: 1, null: false

      t.timestamps
    end

    add_index :budget_line_items, :category
  end
end
