require 'rails_helper'
require 'temping'

RSpec.describe UsernameStringType, type: :model do
  it 'is a String' do
    expect(subject).to be_a ActiveRecord::Type::String
  end

  describe '#cast' do
    it 'downcases and strips leading and trailing spaces' do
      expect(subject.cast('abc')).to eq 'abc'
      expect(subject.cast(' abc')).to eq 'abc'
      expect(subject.cast('abc ')).to eq 'abc'
      expect(subject.cast(' abc ')).to eq 'abc'
      expect(subject.cast(' a bc ')).to eq 'a bc'
      expect(subject.cast('ABC')).to eq 'abc'
      expect(subject.cast(' aB C ')).to eq 'ab c'
    end
  end

  describe '#serialize' do
    it 'downcases and strips leading and trailing spaces' do
      expect(subject.serialize('abc')).to eq 'abc'
      expect(subject.serialize(' abc')).to eq 'abc'
      expect(subject.serialize('abc ')).to eq 'abc'
      expect(subject.serialize(' abc ')).to eq 'abc'
      expect(subject.serialize(' a bc ')).to eq 'a bc'
      expect(subject.serialize('ABC')).to eq 'abc'
      expect(subject.serialize(' aB C ')).to eq 'ab c'
    end
  end
end
