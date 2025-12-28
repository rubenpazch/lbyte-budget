# Integration Guide: Linking Prescriptions with Budget Quotes

This guide explains how to integrate the Budget engine with your existing Rails application that has `Patient` and `Prescription` models.

## Your Application Structure

```
Patient (has_many) → Prescription (has_one) → Budget::Quote
```

## Step-by-Step Integration

### Step 1: Add Foreign Key Migration

In your **main Rails application** (not in the engine), create a migration to add `prescription_id` to the `budget_quotes` table:

```bash
rails generate migration AddPrescriptionToBudgetQuotes prescription:references
```

This creates:

```ruby
class AddPrescriptionToBudgetQuotes < ActiveRecord::Migration[7.0]
  def change
    add_reference :budget_quotes, :prescription, foreign_key: true, index: true
  end
end
```

Run the migration:

```bash
rails db:migrate
```

### Step 2: Update Your Prescription Model

Add the relationship to your `Prescription` model:

```ruby
# app/models/prescription.rb
class Prescription < ApplicationRecord
  belongs_to :patient
  has_one :quote, class_name: 'Budget::Quote', foreign_key: 'prescription_id', dependent: :destroy
  
  # Optional: Automatically create a quote when a prescription is created
  after_create :create_initial_quote
  
  # Delegate common methods to the quote for convenience
  delegate :total, :total_paid, :remaining_balance, :fully_paid?, to: :quote, allow_nil: true
  
  private
  
  def create_initial_quote
    Budget::Quote.create!(
      prescription_id: id,
      customer_name: patient.full_name,
      customer_contact: patient.phone || patient.email,
      notes: "Prescription ##{id}"
    )
  end
end
```

### Step 3: Extend the Budget::Quote Model

In your **main application**, create a decorator or initializer to add the `belongs_to :prescription` association:

**Option A: Using a Decorator (Recommended)**

Create `app/models/budget/quote_decorator.rb`:

```ruby
# app/models/budget/quote_decorator.rb
Budget::Quote.class_eval do
  belongs_to :prescription, optional: true
  
  # Add custom scopes or methods specific to your app
  scope :for_patient, ->(patient_id) {
    joins(:prescription).where(prescriptions: { patient_id: patient_id })
  }
  
  # Helper method to get the patient
  def patient
    prescription&.patient
  end
end
```

**Option B: Using an Initializer**

Create `config/initializers/budget.rb`:

```ruby
# config/initializers/budget.rb
Rails.application.config.to_prepare do
  Budget::Quote.class_eval do
    belongs_to :prescription, optional: true
    
    def patient
      prescription&.patient
    end
  end
end
```

### Step 4: Update Your Patient Model

```ruby
# app/models/patient.rb
class Patient < ApplicationRecord
  has_many :prescriptions, dependent: :destroy
  has_many :quotes, through: :prescriptions, class_name: 'Budget::Quote'
  
  # Get all quotes for this patient
  def all_quotes
    Budget::Quote.joins(:prescription).where(prescriptions: { patient_id: id })
  end
  
  # Calculate total amount owed across all quotes
  def total_outstanding
    all_quotes.sum { |quote| quote.remaining_balance }
  end
end
```

## Usage Examples

### Creating a Prescription with Quote

```ruby
# Create patient
patient = Patient.create!(
  name: "María González",
  email: "maria@example.com",
  phone: "555-1234"
)

# Create prescription (automatically creates quote via callback)
prescription = patient.prescriptions.create!(
  doctor: "Dr. Smith",
  prescription_details: "OD: -2.00, OS: -1.75"
)

# Access the quote
quote = prescription.quote
# => #<Budget::Quote id: 1, customer_name: "María González", ...>

# Add line items to the quote
quote.add_line_item(
  description: "Lentes progresivos",
  price: 150.00,
  category: :lente,
  quantity: 1
)

quote.add_line_item(
  description: "Montura premium",
  price: 80.00,
  category: :montura
)

# Record initial payment (adelanto)
quote.add_payment(
  amount: 115.00,
  payment_method: "efectivo",
  notes: "Adelanto - 50%"
)

# Check status
puts quote.total              # => 230.0
puts quote.total_paid         # => 115.0
puts quote.remaining_balance  # => 115.0
puts quote.fully_paid?        # => false
```

### Working with API Endpoints

```ruby
# In your controllers, you can pass prescription_id when creating quotes

# POST /budget/quotes
{
  "quote": {
    "prescription_id": 123,
    "customer_name": "María González",
    "customer_contact": "555-1234"
  }
}

# Or create through prescription
prescription = Prescription.find(params[:id])
quote = prescription.create_quote!(
  customer_name: prescription.patient.name,
  customer_contact: prescription.patient.phone
)
```

### Querying Across Models

```ruby
# Find all quotes for a specific patient
patient = Patient.find(1)
patient.quotes
# or
patient.all_quotes

# Find quote by prescription
prescription = Prescription.find(1)
quote = prescription.quote

# Find prescription from quote
quote = Budget::Quote.find(1)
prescription = quote.prescription
patient = quote.patient

# Get all pending quotes for a patient
patient.quotes.joins(:payments)
  .group('budget_quotes.id')
  .having('SUM(budget_payments.amount) < ?', patient.quotes.sum(&:total))
```

### Controller Example

```ruby
# app/controllers/prescriptions_controller.rb
class PrescriptionsController < ApplicationController
  def show
    @prescription = Prescription.includes(quote: [:line_items, :payments]).find(params[:id])
    @quote = @prescription.quote
  end
  
  def create
    @prescription = current_patient.prescriptions.build(prescription_params)
    
    if @prescription.save
      # Quote is created automatically via callback
      # Or create manually:
      # @prescription.create_quote!(
      #   customer_name: current_patient.name,
      #   customer_contact: current_patient.phone
      # )
      
      redirect_to @prescription, notice: 'Prescription and quote created.'
    else
      render :new
    end
  end
end
```

### View Example

```erb
<!-- app/views/prescriptions/show.html.erb -->
<h1>Prescription #<%= @prescription.id %></h1>

<h2>Patient Information</h2>
<p>Name: <%= @prescription.patient.name %></p>
<p>Contact: <%= @prescription.patient.phone %></p>

<h2>Quote Summary</h2>
<% if @prescription.quote %>
  <p>Total: $<%= number_to_currency(@prescription.quote.total) %></p>
  <p>Paid: $<%= number_to_currency(@prescription.quote.total_paid) %></p>
  <p>Balance: $<%= number_to_currency(@prescription.quote.remaining_balance) %></p>
  <p>Status: <%= @prescription.quote.fully_paid? ? 'PAID' : 'PENDING' %></p>
  
  <h3>Line Items</h3>
  <ul>
    <% @prescription.quote.line_items.each do |item| %>
      <li><%= item.description %> - $<%= item.subtotal %></li>
    <% end %>
  </ul>
  
  <h3>Payments</h3>
  <ul>
    <% @prescription.quote.payments.each do |payment| %>
      <li>
        <%= payment.payment_date.strftime('%Y-%m-%d') %> - 
        $<%= payment.amount %> 
        (<%= payment.payment_method_name %>)
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No quote created yet.</p>
  <%= link_to 'Create Quote', create_quote_prescription_path(@prescription), method: :post %>
<% end %>
```

## API Integration

### Creating Quote with Prescription

```javascript
// Create prescription with quote
const response = await fetch('/prescriptions', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    prescription: {
      patient_id: 123,
      doctor: "Dr. Smith",
      prescription_details: "OD: -2.00"
    }
  })
});

const prescription = await response.json();
const quoteId = prescription.quote.id;

// Add items to the quote
await fetch(`/budget/quotes/${quoteId}/line_items`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    line_item: {
      description: "Lentes progresivos",
      price: 150.00,
      category: "lente"
    }
  })
});
```

### Fetching Quote for Prescription

```javascript
// Get prescription with quote details
const response = await fetch(`/prescriptions/${prescriptionId}`);
const prescription = await response.json();

console.log(prescription.quote.total);
console.log(prescription.quote.remaining_balance);
```

## Database Schema

After integration, your schema will look like:

```
patients
├── id
├── name
├── email
├── phone
└── ...

prescriptions
├── id
├── patient_id (FK → patients)
├── doctor
├── prescription_details
└── ...

budget_quotes
├── id
├── prescription_id (FK → prescriptions) ← NEW!
├── customer_name
├── customer_contact
├── quote_date
└── ...

budget_line_items
├── id
├── budget_quote_id (FK → budget_quotes)
├── description
├── price
└── ...

budget_payments
├── id
├── budget_quote_id (FK → budget_quotes)
├── amount
├── payment_date
└── ...
```

## Best Practices

1. **Use Callbacks Wisely**: Automatically create quotes when prescriptions are created
2. **Delegate Methods**: Use `delegate` in Prescription to avoid `prescription.quote.total`
3. **Validations**: Ensure prescription_id is present when needed
4. **Eager Loading**: Use `includes` to avoid N+1 queries
5. **Soft Deletes**: Consider using `dependent: :destroy` or `dependent: :nullify`

## Testing

```ruby
# spec/models/prescription_spec.rb
RSpec.describe Prescription, type: :model do
  describe 'associations' do
    it { should belong_to(:patient) }
    it { should have_one(:quote).class_name('Budget::Quote') }
  end
  
  describe 'callbacks' do
    it 'creates a quote after creation' do
      patient = create(:patient)
      prescription = patient.prescriptions.create!(doctor: 'Dr. Smith')
      
      expect(prescription.quote).to be_present
      expect(prescription.quote.customer_name).to eq(patient.name)
    end
  end
  
  describe 'delegations' do
    it 'delegates total to quote' do
      prescription = create(:prescription)
      prescription.quote.add_line_item(description: 'Test', price: 100)
      
      expect(prescription.total).to eq(100)
    end
  end
end
```

## Troubleshooting

### Quote not being created automatically

Make sure the callback is defined correctly and the patient has a name:

```ruby
after_create :create_initial_quote, if: -> { patient.present? }
```

### Association not found error

Ensure you've restarted your Rails server after adding the initializer:

```bash
rails restart
# or
touch tmp/restart.txt
```

### Foreign key constraint fails

The `prescription_id` column must allow NULL if you want to create standalone quotes:

```ruby
add_reference :budget_quotes, :prescription, foreign_key: true, null: true
```

## Questions?

See also:
- [RAILS_USAGE.md](RAILS_USAGE.md) - General Rails integration
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API endpoints reference
