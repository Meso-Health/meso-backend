require 'rails_helper'
include FormatterHelper

RSpec.describe FormatterHelper do
  describe 'format_currency' do
    it 'formats correctly' do
      expect(format_currency(9870)).to eq '98.70'
    end
  end

  describe 'format_short_id' do
    it 'formats UUIDs' do
      expect(format_short_id('2c6de5e1-89d1-438e-aef5-f208f42737b1')). to eq '2C6DE5E1'
    end
  end
end
