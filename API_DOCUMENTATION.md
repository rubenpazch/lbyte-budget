# Budget Engine - JSON API Documentation

## Overview

The Budget Engine provides a complete REST JSON API for managing quotes, line items, and payments. All endpoints return JSON responses using JBuilder.

## Base URL

When mounted in your Rails app at `/budget`:
```
https://your-app.com/budget
```

## Authentication

The engine doesn't include authentication. Implement authentication in your main Rails app using `before_action` callbacks.

## API Endpoints

### Quotes

#### List All Quotes
```
GET /budget/quotes
```

**Parameters:**
- `page` (optional) - Page number for pagination
- `per_page` (optional) - Items per page (default: 20)

**Response:**
```json
[
  {
    "id": 1,
    "customer_name": "María González",
    "customer_contact": "555-1234",
    "quote_date": "2025-11-29T10:30:00.000Z",
    "created_at": "2025-11-29T10:30:00.000Z",
    "line_items_count": 3,
    "payments_count": 1,
    "totals": {
      "total": 265.00,
      "total_paid": 132.50,
      "remaining_balance": 132.50,
      "fully_paid": false
    }
  }
]
```

#### Get Quote Details
```
GET /budget/quotes/:id
```

**Response:**
```json
{
  "id": 1,
  "customer_name": "María González",
  "customer_contact": "555-1234",
  "notes": "Prefiere montura liviana",
  "quote_date": "2025-11-29T10:30:00.000Z",
  "created_at": "2025-11-29T10:30:00.000Z",
  "updated_at": "2025-11-29T10:30:00.000Z",
  "line_items": [
    {
      "id": 1,
      "description": "Lentes progresivos alta gama",
      "price": 150.00,
      "category": "lente",
      "quantity": 1,
      "category_name": "Lente",
      "subtotal": 150.00,
      "created_at": "2025-11-29T10:31:00.000Z"
    },
    {
      "id": 2,
      "description": "Montura de titanio",
      "price": 80.00,
      "category": "montura",
      "quantity": 1,
      "category_name": "Montura",
      "subtotal": 80.00,
      "created_at": "2025-11-29T10:32:00.000Z"
    }
  ],
  "payments": [
    {
      "id": 1,
      "amount": 132.50,
      "payment_date": "2025-11-29T10:35:00.000Z",
      "payment_method": "efectivo",
      "payment_method_name": "Efectivo",
      "notes": "Adelanto 50%",
      "created_at": "2025-11-29T10:35:00.000Z"
    }
  ],
  "totals": {
    "total": 265.00,
    "total_paid": 132.50,
    "remaining_balance": 132.50,
    "fully_paid": false
  },
  "category_breakdown": {
    "lente": 150.00,
    "montura": 80.00,
    "tratamiento": 35.00
  }
}
```

#### Create Quote
```
POST /budget/quotes
```

**Request Body:**
```json
{
  "quote": {
    "customer_name": "María González",
    "customer_contact": "555-1234",
    "notes": "Cliente preferencial"
  }
}
```

**Response:** Same as GET /budget/quotes/:id (201 Created)

#### Update Quote
```
PATCH /budget/quotes/:id
```

**Request Body:**
```json
{
  "quote": {
    "customer_contact": "555-5678",
    "notes": "Updated notes"
  }
}
```

**Response:** Same as GET /budget/quotes/:id (200 OK)

#### Delete Quote
```
DELETE /budget/quotes/:id
```

**Response:** 204 No Content

#### Get Quote Summary
```
GET /budget/quotes/:id/summary
```

**Response:**
```json
{
  "id": 1,
  "customer_name": "María González",
  "customer_contact": "555-1234",
  "date": "2025-11-29T10:30:00.000Z",
  "line_items_count": 3,
  "total": 265.00,
  "total_paid": 132.50,
  "remaining_balance": 132.50,
  "fully_paid": false,
  "category_breakdown": {
    "lente": 150.00,
    "montura": 80.00,
    "tratamiento": 35.00
  },
  "payments_count": 1
}
```

### Line Items

#### List Quote Line Items
```
GET /budget/quotes/:quote_id/line_items
```

**Response:**
```json
[
  {
    "id": 1,
    "description": "Lentes progresivos",
    "price": 150.00,
    "category": "lente",
    "quantity": 1,
    "category_name": "Lente",
    "subtotal": 150.00,
    "created_at": "2025-11-29T10:31:00.000Z"
  }
]
```

#### Get Line Item Details
```
GET /budget/quotes/:quote_id/line_items/:id
```

**Response:**
```json
{
  "id": 1,
  "description": "Lentes progresivos alta gama",
  "price": 150.00,
  "category": "lente",
  "quantity": 1,
  "category_name": "Lente",
  "subtotal": 150.00,
  "quote_id": 1,
  "created_at": "2025-11-29T10:31:00.000Z",
  "updated_at": "2025-11-29T10:31:00.000Z"
}
```

#### Create Line Item
```
POST /budget/quotes/:quote_id/line_items
```

**Request Body:**
```json
{
  "line_item": {
    "description": "Lentes progresivos",
    "price": 150.00,
    "category": "lente",
    "quantity": 1
  }
}
```

**Categories:** `lente`, `montura`, `tratamiento`, `other`

**Response:** Same as GET line_item (201 Created)

#### Update Line Item
```
PATCH /budget/quotes/:quote_id/line_items/:id
```

**Request Body:**
```json
{
  "line_item": {
    "price": 160.00,
    "quantity": 2
  }
}
```

**Response:** Same as GET line_item (200 OK)

#### Delete Line Item
```
DELETE /budget/quotes/:quote_id/line_items/:id
```

**Response:** 204 No Content

### Payments

#### List Quote Payments
```
GET /budget/quotes/:quote_id/payments
```

**Response:**
```json
[
  {
    "id": 1,
    "amount": 132.50,
    "payment_date": "2025-11-29T10:35:00.000Z",
    "payment_method": "efectivo",
    "payment_method_name": "Efectivo",
    "notes": "Adelanto 50%",
    "created_at": "2025-11-29T10:35:00.000Z"
  }
]
```

#### Get Payment Details
```
GET /budget/quotes/:quote_id/payments/:id
```

**Response:**
```json
{
  "id": 1,
  "amount": 132.50,
  "payment_date": "2025-11-29T10:35:00.000Z",
  "payment_method": "efectivo",
  "payment_method_name": "Efectivo",
  "notes": "Adelanto 50%",
  "quote_id": 1,
  "created_at": "2025-11-29T10:35:00.000Z",
  "updated_at": "2025-11-29T10:35:00.000Z"
}
```

#### Create Payment
```
POST /budget/quotes/:quote_id/payments
```

**Request Body:**
```json
{
  "payment": {
    "amount": 132.50,
    "payment_method": "efectivo",
    "notes": "Adelanto 50%"
  }
}
```

**Payment Methods:** `efectivo`, `tarjeta`, `transferencia`, `cheque`, `other`

**Response:** Same as GET payment (201 Created)

#### Update Payment
```
PATCH /budget/quotes/:quote_id/payments/:id
```

**Request Body:**
```json
{
  "payment": {
    "amount": 150.00,
    "notes": "Updated amount"
  }
}
```

**Response:** Same as GET payment (200 OK)

#### Delete Payment
```
DELETE /budget/quotes/:quote_id/payments/:id
```

**Response:** 204 No Content

## Error Responses

### Validation Errors (422 Unprocessable Entity)
```json
{
  "errors": [
    "Customer name can't be blank",
    "Price must be greater than or equal to 0"
  ]
}
```

### Not Found (404)
```json
{
  "error": "Record not found"
}
```

## Example Usage

### Complete Workflow

```javascript
// 1. Create a quote
const quote = await fetch('/budget/quotes', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    quote: {
      customer_name: 'María González',
      customer_contact: 'maria@example.com'
    }
  })
}).then(r => r.json());

// 2. Add line items
await fetch(`/budget/quotes/${quote.id}/line_items`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    line_item: {
      description: 'Lentes progresivos',
      price: 150.00,
      category: 'lente'
    }
  })
});

await fetch(`/budget/quotes/${quote.id}/line_items`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    line_item: {
      description: 'Montura titanio',
      price: 80.00,
      category: 'montura'
    }
  })
});

// 3. Get updated quote with totals
const updatedQuote = await fetch(`/budget/quotes/${quote.id}`)
  .then(r => r.json());

console.log('Total:', updatedQuote.totals.total); // 230.00

// 4. Add payment
await fetch(`/budget/quotes/${quote.id}/payments`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    payment: {
      amount: 115.00,
      payment_method: 'efectivo',
      notes: 'Adelanto 50%'
    }
  })
});

// 5. Check remaining balance
const finalQuote = await fetch(`/budget/quotes/${quote.id}`)
  .then(r => r.json());

console.log('Remaining:', finalQuote.totals.remaining_balance); // 115.00
console.log('Fully paid?', finalQuote.totals.fully_paid); // false
```

## Mounting in Your Rails App

In your main app's `config/routes.rb`:

```ruby
mount Budget::Engine => '/budget'
```

This makes all endpoints available at `/budget/*`.

## Adding Authentication

In your main Rails app:

```ruby
# config/initializers/budget.rb
Budget::QuotesController.class_eval do
  before_action :authenticate_user!
end

Budget::LineItemsController.class_eval do
  before_action :authenticate_user!
end

Budget::PaymentsController.class_eval do
  before_action :authenticate_user!
end
```

Or use concerns:

```ruby
# app/controllers/concerns/budget_authentication.rb
module BudgetAuthentication
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_user!
  end
end

# config/initializers/budget.rb
[
  Budget::QuotesController,
  Budget::LineItemsController,
  Budget::PaymentsController
].each do |controller|
  controller.include BudgetAuthentication
end
```

## Pagination

The quotes index endpoint supports pagination via kaminari (if available in your app):

```
GET /budget/quotes?page=2&per_page=50
```

Install kaminari in your main app:
```ruby
gem 'kaminari'
```

## CORS Configuration

For API access from different domains, configure CORS in your main Rails app:

```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # or specific domains
    resource '/budget/*',
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options]
  end
end
```
