require 'rails_helper'

RSpec.describe AdministrativeDivision, type: :model do
  describe 'Validations' do
    describe 'name' do
      it 'expects name to be not blank' do
        expect(build(:administrative_division, name: nil)).to_not be_valid
        expect(build(:administrative_division, name: '')).to_not be_valid
        expect(build(:administrative_division, name: 'blah')).to be_valid
      end
    end

    describe 'level' do
      it 'expects level to be not blank' do
        expect(build(:administrative_division, level: nil)).to_not be_valid
        expect(build(:administrative_division, level: '')).to_not be_valid
        expect(build(:administrative_division, level: 'country')).to be_valid
      end
    end
  end

  context 'self_and methods' do
    let!(:f1) { create(:administrative_division, level: 'first') }
    let!(:s1) { create(:administrative_division, level: 'second', parent: f1) }
    let!(:s2) { create(:administrative_division, level: 'second', parent: f1) }
    let!(:t11) { create(:administrative_division, level: 'third', parent: s1) }
    let!(:t12) { create(:administrative_division, level: 'third', parent: s1) }
    let!(:t21) { create(:administrative_division, level: 'third', parent: s2) }

    context '#self_and_descendants' do
      it 'bottom node should return only itself' do
        expect(t21.self_and_descendants).to eq [t21]
      end

      it 'nodes at the 2nd to last level should return itself and its leaves' do
        expect(s1.self_and_descendants).to eq [s1, t11, t12]
      end

      it 'nodes at multiple levels from the bottom should return all its descendants' do
        expect(f1.self_and_descendants).to eq [f1, s1, s2, t11, t12, t21]
      end
    end

    context '#self_and_ancestors' do
      it 'returns itself and all ancestors' do
        expect(t21.self_and_ancestors).to eq [t21, s2, f1]
        expect(t12.self_and_ancestors).to eq [t12, s1, f1]
        expect(t11.self_and_ancestors).to eq [t11, s1, f1]
        expect(s2.self_and_ancestors).to eq [s2, f1]
        expect(s1.self_and_ancestors).to eq [s1, f1]
        expect(f1.self_and_ancestors).to eq [f1]
      end
    end
  end
end
