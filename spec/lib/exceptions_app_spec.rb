require 'rails_helper'
require 'rack/test'

RSpec.describe ExceptionsApp do
  describe '.call' do
    include Rack::Test::Methods
    let(:app) { described_class }

    context 'by default' do
      it 'handles exceptions with #internal_server_error' do
        exception = SystemExit.new('message')
        env 'action_dispatch.exception', exception

        get '/'
        json = JSON.parse(last_response.body)
        expect(json['type']).to eq 'internal_server_error'
      end
    end
  end

  describe '.for' do
    it 'sets up the response to an exception and returns the instance' do
      result = described_class.for(:not_found)
      expect(result).to be_a described_class
    end
  end

  describe '#render' do
    it 'renders the exception for the provided controller' do
      double = instance_double('ActionController::Metal')
      expect(double).to receive(:content_type=)
      expect(double).to receive(:status=)
      expect(double).to receive(:response_body=)

      described_class.for(:not_found).render(double)
    end
  end

  describe ExceptionsApp::ResponseBuilder do
    describe '#response_for' do
      it 'calls through to the specified response' do
        exception = double('Exception')
        expect(subject).to receive(:not_acceptable).with(exception)

        subject.response_for :not_acceptable, exception
      end

      it 'adds the response type to the body' do
        subject.response_for :not_acceptable
        expect(subject.body[:type]).to eq :not_acceptable
      end
    end

    specify '#bad_request' do
      subject.bad_request
      expect(subject.status).to eq 400
    end

    specify '#basic_authentication_incorrect' do
      subject.basic_authentication_incorrect
      expect(subject.status).to eq 401
      expect(subject.body[:message]).to eq 'The provided username/password combination is incorrect'
    end

    specify '#token_authentication_incorrect' do
      subject.token_authentication_incorrect
      expect(subject.status).to eq 401
      expect(subject.body[:message]).to eq 'The provided authentication token is invalid'
    end

    specify '#token_authentication_expired' do
      subject.token_authentication_expired
      expect(subject.status).to eq 401
      expect(subject.body[:message]).to eq 'The provided authentication token has expired'
    end

    specify '#not_found' do
      subject.not_found
      expect(subject.status).to eq 404
    end

    specify '#forbidden' do
      subject.forbidden
      expect(subject.status).to eq 403
    end

    specify '#method_not_allowed' do
      subject.method_not_allowed
      expect(subject.status).to eq 405
    end

    specify '#not_acceptable' do
      subject.not_acceptable
      expect(subject.status).to eq 406
    end

    specify '#conflict' do
      subject.conflict
      expect(subject.status).to eq 409
    end

    specify '#unprocessable_entity' do
      subject.unprocessable_entity
      expect(subject.status).to eq 422
    end

    describe '#validation_failed' do
      context 'when provided with an exception with a record' do
        let(:member) { build_stubbed(:member, card_id: '123').tap(&:valid?) }
        let(:exception) { ActiveRecord::RecordInvalid.new(member) }

        it 'returns 422 with the details of the validation errors' do
          expect(member).to_not be_valid

          subject.validation_failed(exception)

          expect(subject.status).to eq 422
          expect(subject.body[:message]).to eq 'Validation failed'
          expect(subject.body[:errors].size).to eq 1
          expect(subject.body[:errors][:card_id]).to eq ["Card does not follow the Meso Card ID format"]
        end
      end
    end

    specify '#internal_server_error' do
      subject.internal_server_error
      expect(subject.status).to eq 500
    end

    specify '#not_implemented' do
      subject.not_implemented
      expect(subject.status).to eq 501
    end
  end
end
