# frozen_string_literal: true

class CreateBudgetPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :budget_payments do |t|
      t.references :budget_quote, null: false, foreign_key: true, index: true
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0.0
      t.datetime :payment_date, null: false
      t.string :payment_method, default: 'efectivo'
      t.text :notes

      t.timestamps
    end

    add_index :budget_payments, :payment_date
    add_index :budget_payments, :payment_method
  end
end
