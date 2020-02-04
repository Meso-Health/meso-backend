shared_context :representer do |factory_options=nil, representer_options={}|
  let(:factory_name) { described_class.name.chomp('Representer').underscore.to_sym }
  let(:record) { build_stubbed(factory_name, factory_options) }
  subject { described_class.new(record) }
end

shared_examples :allow_reads do |field, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'allows reading the field' do
    expect(subject.to_hash(representer_options).keys).to include(field)
  end
end

shared_examples :does_not_allow_reads do |field, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'does not allow reading the field' do
    expect(subject.to_hash(representer_options).keys).to_not include(field)
  end
end

# We use `represented.attributes` for all write tests because `to_hash` requires the attribute to also be readable
# It's worth noting that associations are NOT included in `represented.attributes`, so these tests must be implemented manually.

shared_examples :allow_writes_for_new_records do |field, value, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'allows writing the field' do
    allow(record).to receive_messages(persisted?: false)

    subject.from_hash({field => value}, representer_options)
    expect(subject.represented.attributes).to include(field => value)
  end
end

shared_examples :allow_writes_for_persisted_records do |field, value, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'allows writing the field' do
    allow(record).to receive_messages(persisted?: true)

    subject.from_hash({field => value}, representer_options)
    expect(subject.represented.attributes).to include(field => value)
  end
end

shared_examples :does_not_allow_writes_for_new_records do |field, value, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'does not allow writing the field' do
    allow(record).to receive_messages(persisted?: false)

    subject.from_hash({field => value}, representer_options)
    expect(subject.represented.attributes).to_not include(field => value)
  end
end

shared_examples :does_not_allow_writes_for_persisted_records do |field, value, factory_options=nil, representer_options={}|
  include_context :representer, factory_options, representer_options

  it 'does not allow writing the field' do
    allow(record).to receive_messages(persisted?: true)

    subject.from_hash({field => value}, representer_options)
    expect(subject.represented.attributes).to_not include(field => value)
  end
end

shared_examples :allow_writes do |field, value, factory_options=nil, representer_options={}|
  it_behaves_like :allow_writes_for_new_records, field, value, factory_options, representer_options
  it_behaves_like :allow_writes_for_persisted_records, field, value, factory_options, representer_options
end

shared_examples :allow_writes_for_new_records_only do |field, value, factory_options=nil, representer_options={}|
  it_behaves_like :allow_writes_for_new_records, field, value, factory_options, representer_options
  it_behaves_like :does_not_allow_writes_for_persisted_records, field, value, factory_options, representer_options
end

shared_examples :does_not_allow_writes do |field, value, factory_options=nil, representer_options={}|
  it_behaves_like :does_not_allow_writes_for_new_records, field, value, factory_options, representer_options
  it_behaves_like :does_not_allow_writes_for_persisted_records, field, value, factory_options, representer_options
end

shared_examples :allow_reads_and_writes do |field, value, factory_options=nil, representer_options={}|
  it_behaves_like :allow_reads, field, factory_options, representer_options
  it_behaves_like :allow_writes, field, value, factory_options, representer_options
end
