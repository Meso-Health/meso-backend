require 'rails_helper'

RSpec.describe Card, type: :model do
  specify '#revoked?' do
    expect(build_stubbed(:card)).to_not be_revoked
    expect(build_stubbed(:card, :revoked)).to be_revoked
  end

  describe '.unassigned' do
    let(:card_1) { create(:card) }
    let(:card_2) { create(:card) }
    let(:card_3) { create(:card) }

    before do
      create(:member, card: card_2)
    end

    it 'selects cards not assigned to a member' do
      expect(Card.unassigned).to match_array([card_1, card_3])
    end
  end

  describe '#format_with_spaces' do
    it 'returns the card with spaces' do
      expect(build(:card, id: "ETH123123").format_with_spaces).to eq 'ETH 123 123'
      expect(build(:card, id: "UGA000002").format_with_spaces).to eq 'UGA 000 002'
    end
  end

  describe '#revoke!' do
    subject { build(:card) }

    it 'sets revoked_at' do
      time = Time.zone.now
      Timecop.freeze(time) do
        subject.revoke!
        expect(subject).to be_revoked
        expect(subject.revoked_at).to eq time
      end
    end

    it 'unassigns the card_id from a member' do
      member = create(:member, card: subject)
      expect(member.card_id).to be

      subject.revoke!
      expect(member.card_id).to be_nil
    end

    context 'when the card has already been revoked' do
      it 'does not reassign revoked_at' do
        time = Time.zone.now
        Timecop.freeze(time) do
          subject.revoke!
        end

        Timecop.freeze(time + 1.day) do
          subject.revoke!
          expect(subject).to be_revoked
          expect(subject.revoked_at).to eq time
        end

      end
    end
  end
end
