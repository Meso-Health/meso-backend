require 'rails_helper'

RSpec.describe UserRepresenter do
  let(:user) { build_stubbed(:user) }
  subject { described_class.new(user) }

  describe '#id' do
    it_behaves_like :allow_reads, 'id'
    it_behaves_like :does_not_allow_writes, 'id', 101, id: 100
  end

  describe '#created_at' do
    it_behaves_like :allow_reads, 'created_at'
    it_behaves_like :does_not_allow_writes, 'created_at', Time.zone.now, created_at: Time.zone.now - 1.hour
  end

  describe '#name' do
    it_behaves_like :allow_reads_and_writes, 'name', 'Bubba', name: 'Forrest'
  end

  describe '#username' do
    it_behaves_like :allow_reads_and_writes, 'username', 'bubbagump', { username: 'forrestgump' }
  end

  describe '#role' do
    it_behaves_like :allow_reads, 'role'
    it_behaves_like :allow_writes_for_new_records_only, 'role', 'admin', role: 'provider'
  end

  describe '#provider_id' do
    it_behaves_like :allow_reads, 'provider_id', provider_id: 1
    it_behaves_like :allow_writes_for_new_records_only, 'provider_id', 2, provider_id: 1
  end

  describe '#password' do
    it_behaves_like :does_not_allow_reads, 'password'

    # cannot use standard shared_examples to test 'password' field write because it's stored as 'password_digest'
    context 'field writes' do
      let(:user) { build_stubbed(:user, password: '123456') }
      let(:new_value) { '654321' }

      context 'new record' do
        it 'allows writing the field' do
          allow(user).to receive_messages(persisted?: false)

          previous_value = user.send('password_digest')
          subject.from_hash({'password' => new_value}, user_options: {current_admin_user: true})
          expect(subject.represented.password_digest).to_not eq previous_value
        end
      end

      context 'persisted record' do
        it 'allows writing the field' do
          allow(user).to receive_messages(persisted?: true)

          previous_value = user.send('password_digest')
          subject.from_hash({'password' => new_value}, user_options: {current_admin_user: true})
          expect(subject.represented.password_digest).to_not eq previous_value
        end
      end
    end
  end

  describe '#added_by' do
    it_behaves_like :allow_reads, 'added_by'
    it_behaves_like :does_not_allow_writes, 'added_by', 'Forrest Gump'
  end
end
