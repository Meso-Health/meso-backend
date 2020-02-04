require 'rails_helper'

RSpec.describe CardIdGenerator do
  describe 'FORMAT_REGEX' do
    it 'follows the ABC123456 format' do
      format = CardIdGenerator::FORMAT_REGEX
      expect('AAA123456').to match format
      expect('RWI290836').to match format
      expect('RWI2908365').to_not match format
      expect('123290836').to_not match format
      expect('ABCD90836').to_not match format
      expect('ABCDEFGHI').to_not match format
    end
  end

  describe '.random' do
    context 'when given no prefix' do
      it 'generates a random UHP ID' do
        expect(CardIdGenerator.random).to match(CardIdGenerator::FORMAT_REGEX)
      end

      it 'correctly UHP IDs with leading zeros' do
        allow(Random).to receive(:rand).and_return(69340)
        expect(CardIdGenerator.random).to end_with('069340')
      end
    end

    context 'when given a valid letter prefix' do
      it 'generates a random UHP ID with that prefix' do
        id = CardIdGenerator.random('RWI')
        expect(id).to match(CardIdGenerator::FORMAT_REGEX)
        expect(id).to start_with('RWI')
      end
    end

    context 'when given an invalid letter prefix' do
      it 'throws an ArgumentError' do
        expect do
          CardIdGenerator.random('!!!')
        end.to raise_error ArgumentError
      end
    end
  end

  describe '.random_prefix' do
    it 'generates a random prefix for a UHP ID' do
      expect(CardIdGenerator.random_prefix).to match(CardIdGenerator::PREFIX_REGEX)
    end
  end

  describe '.unique' do
    it "generates a unique id for the object" do
      expect(CardIdGenerator.unique).to match(CardIdGenerator::FORMAT_REGEX)
    end

    context 'when the randomly generated id has already been issued' do
      it "continues trying until the id is unique" do
        existing = create(:card)
        expect(CardIdGenerator).to receive(:random).and_return(existing.id, 'RWI123456')

        id = CardIdGenerator.unique
        expect(id).to match(CardIdGenerator::FORMAT_REGEX)
        expect(id).to_not eq existing.id
      end
    end
  end
end
