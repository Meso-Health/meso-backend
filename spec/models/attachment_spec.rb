require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'before saving' do
    context 'when the same file has been written to the database' do
      it 'aborts the save and loads the existing record' do
        file = File.open(Rails.root.join("spec/factories/members/photo1.jpg"))
        attachment1 = Attachment.from_data(file)
        attachment2 = create(:attachment, file: file)

        expect(attachment1.id).to eq attachment2.id
        expect(attachment1).to_not be_persisted
        expect(attachment2).to be_persisted

        expect do
          attachment1.save!
        end.to_not raise_error

        expect(attachment1).to be_persisted
      end
    end
  end

  describe '.from_data' do
    let(:file) {  File.open(Rails.root.join("spec/factories/members/photo1.jpg")) }

    it 'initializes an attachment with the data' do
      attachment = Attachment.from_data(file.read)
      expect(attachment).to_not be_persisted
      expect(attachment.id).to be
      expect(attachment.file).to be
    end

    context 'if the data has already been stored as an attachment' do
      let!(:existing_attachment) { create(:attachment, file: file) }

      it 'returns the existing attachment' do
        attachment = Attachment.from_data(file.read)

        expect(attachment).to eq existing_attachment
        expect(attachment).to be_persisted
      end
    end

    context 'if given a File' do
      it 'initializes an attachment with the file contents' do
        attachment = Attachment.from_data(file)
        expect(attachment).to_not be_persisted
        expect(attachment.id).to be
        expect(attachment.file).to be
      end
    end
  end

  describe '.from_dragonfly_uid' do
    it 'creates an attachment with populated attributes from an existing Dragonfly uid' do
      uid = Dragonfly.app.store( File.open(Rails.root.join("spec/factories/members/photo1.jpg")) )

      attachment = Attachment.from_dragonfly_uid(uid)
      expect(attachment).to_not be_persisted
      expect(attachment.id).to be
      expect(attachment.file_uid).to eq uid
      expect(attachment.file_name).to be
      expect(attachment.file_width).to be
      expect(attachment.file_height).to be
      expect(attachment.file_size).to be
    end

    context 'if the file has already been stored as an attachment' do
      let(:existing_attachment) { create(:attachment) }
      let(:attachment) { Attachment.from_dragonfly_uid(existing_attachment.file_uid) }

      it 'returns the existing attachment' do
        expect(attachment).to eq existing_attachment
        expect(attachment).to be_persisted
      end
    end

    context 'if the uid does not point to an existing Dragonfly file' do
      it 'raises an error' do
        expect do
          Attachment.from_dragonfly_uid('asdf')
        end.to raise_error(Dragonfly::Job::Fetch::NotFound)
      end
    end
  end
end
