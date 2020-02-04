require 'rails_helper'
require 'temping'

RSpec.describe ApplicationRecord, type: :model, use_database_rewinder: true do
  describe '#save_with_id_collision!' do
    before do
      Temping.create :test_model, id: :uuid, default: 'gen_random_uuid()' do
        with_columns do |t|
          t.string :name, null: false
        end
      end
    end
    after { Temping.teardown }

    let(:uuid) { SecureRandom.uuid }
    subject { TestModel.new(id: uuid, name: 'bob') }

    context 'when no object exists with the id' do
      it 'saves successfully' do
        expect do
          subject.save_with_id_collision!
        end.to_not raise_error

        expect(subject).to be_persisted
        expect(subject.id).to eq uuid
        expect(subject.name).to eq 'bob'
      end

      it 'does not log to Rollbar' do
        expect(Rollbar).to_not receive(:info)

        subject.save_with_id_collision!
      end

      context 'if the save fails due to any other error' do
        it 'does not retry the transaction' do
          exception = ActiveRecord::StatementInvalid.new('Some error')
          expect(subject).to receive(:save!).and_raise(exception).ordered

          expect do
            subject.save_with_id_collision!
          end.to raise_error ActiveRecord::StatementInvalid

          expect(subject).to_not be_persisted
        end
      end

      context 'if the save fails due to a transaction serialization error' do
        it 'retries the transaction' do
          real_error_message = 'PG::TRSerializationFailure: ERROR: could not serialize access due to read/write dependencies among transactions'
          serialization_exception = ActiveRecord::StatementInvalid.new(real_error_message)
          allow(serialization_exception).to receive_messages(cause: PG::TRSerializationFailure.new)
          expect(subject).to receive(:save!).and_raise(serialization_exception).ordered
          expect(subject).to receive(:save!).and_call_original.ordered

          expect do
            subject.save_with_id_collision!
          end.to_not raise_error

          expect(subject).to be_persisted
        end
      end
    end

    context 'when an object with the id exists in the database already' do
      before do
        existing = TestModel.create!(id: uuid, name: 'sally')
      end

      it 'loads the existing record from the database without saving the current one' do
        expect do
          subject.save_with_id_collision!
        end.to_not raise_error

        expect(subject).to be_persisted
        expect(subject.id).to eq uuid
        expect(subject.name).to eq 'sally'
      end

      it 'logs the aborted save to rollbar' do
        expect(Rollbar).to receive(:info)

        subject.save_with_id_collision!
      end
    end

    context 'when the object has already been saved' do
      before do
        subject.save!
        subject.name = 'sally'
      end

      it 'saves successfully' do
        expect do
          subject.save_with_id_collision!
        end.to_not raise_error

        expect(subject).to be_persisted
        expect(subject.id).to eq uuid
        expect(subject.name).to eq 'sally'
      end

      it 'does not log to Rollbar' do
        expect(Rollbar).to_not receive(:info)

        subject.save_with_id_collision!
      end
    end

    context 'when another kind of exception occurs' do
      before do
        subject.name = nil
      end

      it 'propagates the exception as normal' do
        expect do
          subject.save_with_id_collision!
        end.to raise_error ActiveRecord::StatementInvalid
      end

      it 'does not log to Rollbar' do
        expect(Rollbar).to_not receive(:info)

        expect do
          subject.save_with_id_collision!
        end.to raise_error ActiveRecord::StatementInvalid
      end
    end
  end
end
