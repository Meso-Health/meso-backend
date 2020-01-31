require 'rails_helper'
require 'temping'

RSpec.describe HasAttachments, type: :model do
  before do
    Temping.create :model do
      include HasAttachments

      has_attachments :photos
    end

    Temping.create :attachments_models do
      with_columns do |t|
        t.references :attachment, type: :string, limit: 32, null: false
        t.references :model, null: false
        t.index [:attachment_id, :model_id], unique: true
      end
    end
  end
  after do
    Model.send(:remove_const, 'HABTM_PhotoAttachments') if Model.const_defined?('HABTM_PhotoAttachments')
    Temping.teardown
  end

  let(:model) { Model.new }

  describe '.has_attachments' do
    it 'adds #photo_attachments as a HABTM' do
      expect(model).to respond_to(:photo_attachments)
      expect(Model.reflect_on_association(:photo_attachments).macro).to eq :has_and_belongs_to_many
    end

    it 'adds #preload_photos as a scope' do
      expect(Model.preload_photos).to be_a_kind_of ActiveRecord::Relation
    end
  end

  describe '#photos' do
    it 'returns an array of the underlying Dragonfly attachments' do
      attachment1 = build_stubbed(:attachment)
      attachment2 = build_stubbed(:attachment)
      expect(model).to receive_messages(photo_attachments: [attachment1, attachment2])

      expect(model.photos).to eq [attachment1.file, attachment2.file]
    end
  end

  describe '#add_photo' do
    context 'when given an Attachment that already exists in the list' do
      let(:model) { Model.create! }

      it 'ignores it' do
        attachment = create(:attachment)
        expect(model.photo_attachments).to be_empty

        model.add_photo(attachment)
        expect(model.photo_attachments).to eq [attachment]

        expect do
          model.add_photo(attachment)
        end.to_not raise_error
        expect(model.photo_attachments).to eq [attachment]
      end
    end

    context 'when given an Attachment' do
      it 'sets the underlying #photo_attachment to the Attachment' do
        attachment = create(:attachment)
        expect(model.photo_attachments).to be_empty

        model.add_photo(attachment)
        expect(model.photo_attachments).to eq [attachment]
      end
    end

    context 'when given a Dragonfly attachment' do
      it 'sets the underlying #photo_attachment to an Attachment with the data from the Dragonfly uid object' do
        attachment = create(:attachment)
        expect(model.photo_attachments).to be_empty

        model.add_photo(attachment.file)
        expect(model.photo_attachments).to eq [attachment]
      end
    end

    context 'when given a Dragonfly Job' do
      it 'sets the underlying #photo_attachment to an Attachment from the Dragonfly Job data' do
        attachment = create(:attachment)
        job = Dragonfly.app.fetch(attachment.file_uid)
        expect(model.photo_attachments).to be_empty

        model.add_photo(job)
        expect(model.photo_attachments).to eq [attachment]
      end
    end

    context 'when given a String' do
      it 'sets the underlying #photo_attachment to an Attachment of the string data' do
        string =  File.open(Rails.root.join("spec/factories/members/photo1.jpg")).read
        mock_attachment = build_stubbed(:attachment)
        expect(model.photo_attachments).to be_empty

        expect(Attachment).to receive(:from_data).with(string).and_return(mock_attachment)

        model.add_photo(string)
        expect(model.photo_attachments).to eq [mock_attachment]
      end
    end

    context 'when given a File' do
      it 'sets the underlying #photo_attachment to an Attachment from the File data' do
        file =  File.open(Rails.root.join("spec/factories/members/photo1.jpg"))
        mock_attachment = build_stubbed(:attachment)
        expect(model.photo_attachments).to be_empty

        expect(Attachment).to receive(:from_data).with(file).and_return(mock_attachment)

        model.add_photo(file)
        expect(model.photo_attachments).to eq [mock_attachment]
      end
    end
  end

  describe '#any_photos_stored?' do
    context 'when the model has no photos' do
      it 'returns false' do
        expect(model.any_photos_stored?).to eq false
      end
    end

    context 'when the model has one photo' do
      it 'proxies to the underlying Dragonfly attachment' do
        attachment = build_stubbed(:attachment)
        expect(model).to receive_messages(photo_attachments: [attachment])

        allow(attachment).to receive_messages(file_stored?: true)
        expect(model.any_photos_stored?).to eq true

        allow(attachment).to receive_messages(file_stored?: false)
        expect(model.any_photos_stored?).to eq false
      end
    end

    context 'when the model has multiple photos' do
      it 'proxies to the underlying Dragonfly attachments' do
        attachment1 = build_stubbed(:attachment)
        attachment2 = build_stubbed(:attachment)
        expect(model).to receive_messages(photo_attachments: [attachment1, attachment2])

        allow(attachment1).to receive_messages(file_stored?: true)
        allow(attachment2).to receive_messages(file_stored?: true)
        expect(model.any_photos_stored?).to eq true

        allow(attachment1).to receive_messages(file_stored?: true)
        allow(attachment2).to receive_messages(file_stored?: false)
        expect(model.any_photos_stored?).to eq true

        allow(attachment1).to receive_messages(file_stored?: true)
        allow(attachment2).to receive_messages(file_stored?: false)
        expect(model.any_photos_stored?).to eq true

        allow(attachment1).to receive_messages(file_stored?: false)
        allow(attachment2).to receive_messages(file_stored?: false)
        expect(model.any_photos_stored?).to eq false
      end
    end
  end
end
