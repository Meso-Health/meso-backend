require 'rails_helper'
require 'temping'

RSpec.describe HasAttachment, type: :model do
  before do
    Temping.create :model_with_attachment do
      with_columns do |t|
        t.string :photo_id
      end

      include HasAttachment

      has_attachment :photo
    end
  end
  after { Temping.teardown }

  let(:model) { ModelWithAttachment.new }

  describe '.has_attachment' do
    it 'adds #photo_attachment as a belongs_to' do
      expect(model).to respond_to(:photo_attachment)
      expect(ModelWithAttachment.reflect_on_association(:photo_attachment).macro).to eq :belongs_to
    end

    it 'adds #preload_photo as a scope' do
      expect(ModelWithAttachment.preload_photo).to be_a_kind_of ActiveRecord::Relation
    end
  end

  describe '#photo' do
    it 'returns the underlying Dragonfly attachment' do
      attachment = build_stubbed(:attachment)
      expect(model).to receive_messages(photo_attachment: attachment)

      expect(model.photo).to be_a Dragonfly::Model::Attachment
      expect(model.photo).to be attachment.file
    end
  end

  describe '#photo=' do
    context 'when given nil' do
      it 'unsets underlying #photo_attachment association' do
        model.photo_attachment = build_stubbed(:attachment)
        expect(model.photo_attachment).to_not be_nil

        model.photo = nil
        expect(model.photo_attachment).to be_nil
      end
    end

    context 'when given an Attachment' do
      it 'sets the underlying #photo_attachment to the Attachment' do
        attachment = create(:attachment)
        expect(model.photo_attachment).to be_nil

        model.photo = attachment
        expect(model.photo_attachment).to be attachment
      end
    end

    context 'when given a Dragonfly attachment' do
      it 'sets the underlying #photo_attachment to an Attachment with the data from the Dragonfly uid object' do
        attachment = create(:attachment)
        expect(model.photo_attachment).to be_nil

        model.photo = attachment.file
        expect(model.photo_attachment).to eq attachment
      end
    end

    context 'when given a Dragonfly Job' do
      it 'sets the underlying #photo_attachment to an Attachment from the Dragonfly Job data' do
        attachment = create(:attachment)
        job = Dragonfly.app.fetch(attachment.file_uid)
        expect(model.photo_attachment).to be_nil

        model.photo = job
        expect(model.photo_attachment).to eq attachment
      end
    end

    context 'when given a String' do
      it 'sets the underlying #photo_attachment to an Attachment of the string data' do
        string =  File.open(Rails.root.join("spec/factories/members/photo1.jpg")).read
        mock_attachment = build_stubbed(:attachment)
        expect(model.photo_attachment).to be_nil

        expect(Attachment).to receive(:from_data).with(string).and_return(mock_attachment)

        model.photo = string
        expect(model.photo_attachment).to eq mock_attachment
      end
    end

    context 'when given a File' do
      it 'sets the underlying #photo_attachment to an Attachment from the File data' do
        file =  File.open(Rails.root.join("spec/factories/members/photo1.jpg"))
        mock_attachment = build_stubbed(:attachment)
        expect(model.photo_attachment).to be_nil

        expect(Attachment).to receive(:from_data).with(file).and_return(mock_attachment)

        model.photo = file
        expect(model.photo_attachment).to be mock_attachment
      end
    end
  end

  describe '#photo_stored?' do
    context 'when the model does not have a photo' do
      it 'returns false' do
        expect(model.photo_stored?).to eq false
      end
    end

    context 'when the model has a photo' do
      it 'proxies to the underlying Dragonfly attachment' do
        attachment = build_stubbed(:attachment)
        expect(model).to receive_messages(photo_attachment: attachment)
        expect(attachment).to receive_messages(file_stored?: true)

        expect(model.photo_stored?).to eq true
      end
    end
  end
end
