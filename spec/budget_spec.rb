# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget do
  it 'has a version number' do
    expect(Budget::VERSION).not_to be_nil
    expect(Budget::VERSION).to eq('0.1.0')
  end

  describe 'Budget::Error' do
    it 'is a StandardError subclass' do
      expect(Budget::Error).to be < StandardError
    end

    it 'can be raised and rescued' do
      expect { raise Budget::Error, 'Test error' }.to raise_error(Budget::Error, 'Test error')
    end
  end
end
