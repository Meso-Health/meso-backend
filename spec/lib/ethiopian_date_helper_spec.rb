require 'rails_helper'
include EthiopianDateHelper

RSpec.describe EthiopianDateHelper do
  describe 'from_gregorian_date_to_ethiopian_date_string' do
    it 'does the conversion correctly for all days in the past ~100 years' do
      pairs = file_fixture("gregorian_ethiopian_date_examples.txt").read.split("\n")
      pairs.each do |pair|
        (gregorian_date_string, formatted_ethiopian_date) = pair.split(",")
        gregorian_date = Date.parse(gregorian_date_string)
        expect(from_gregorian_date_to_ethiopian_date_string(gregorian_date)).to eq formatted_ethiopian_date
      end
    end

    it 'returns error when input is invalid' do
      expect do
        from_gregorian_to_ethiopian(2018, 0, 1)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(2018, 1, 0)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(2018, -10, 5)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(2018, 15, 1)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(2018, 15, 55)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(2018, 2, 29)
      end.to raise_error ArgumentError

      expect do
        from_gregorian_to_ethiopian(1582, 10, 10)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(-1000, 10, 10)
      end.to raise_error ArgumentError
    end
  end

  describe 'from_ethiopian_date_string_to_gregorian_date' do
    it 'does the conversion correctly for all days in the past ~100 years' do
      pairs = file_fixture("gregorian_ethiopian_date_examples.txt").read.split("\n")
      pairs.each do |pair|
        (gregorian_date, ethiopian_date_string) = pair.split(",")
        expect(from_ethiopian_date_string_to_gregorian_date(ethiopian_date_string)).to eq gregorian_date
      end
    end

    it 'returns error when input is invalid' do
      expect do
        from_ethiopian_to_gregorian(2018, 0, 1)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(2018, 1, 0)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(2018, -1, 5)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(2018, 5, -01)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(2018, 5, 35)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(2018, 15, 3)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(1582, 10, 10)
      end.to raise_error ArgumentError

      expect do
        from_ethiopian_to_gregorian(-1000, 10, 10)
      end.to raise_error ArgumentError
    end
  end
end
