require 'spec_helper'
require 'byebug'

describe 'Excluding a path from running when' do
  subject { distributor.all_files.any? { |f| f.include? banished_dir } }

  let(:exclude_path) { ENV['BOOSTERS_EXCLUDE_PATH'] }
  let(:banished_dir) { '/integration/' }
  let(:file_pattern) { 'spec/**/*_spec.rb' } # This value is hardcoded in the Rspec boosters
  let(:distributor) { TestBoosters::Files::Distributor.new(nil, file_pattern, 12, exclude_path) }

  after { ENV.delete('BOOSTERS_EXCLUDE_PATH') }

  context 'an exclusion path is specified' do
    before { ENV['BOOSTERS_EXCLUDE_PATH'] = 'spec/integration/' }

    it 'files filtered out correctly' do
      expect(subject).to be false
    end
  end

  context 'an specific file is passed' do
    before { ENV['BOOSTERS_EXCLUDE_PATH'] = 'cucumber_spec.rb' }

    it 'files filtered out correctly' do
      expect(subject).to be true
      expect(distributor.all_files).not_to include('spec/integration/cucumber_spec.rb')
    end
  end

  context 'no exclusion path is specified' do
    it 'nothing filtered out' do
      expect(subject).to be true
    end
  end

  context 'an empty exlusion path is passed' do
    before { ENV['BOOSTERS_EXCLUDE_PATH'] = '' }

    it 'nothing filtered out' do
      expect(subject).to be true
    end
  end

  context 'a nil path is passed' do
    before { ENV['BOOSTERS_EXCLUDE_PATH'] = nil }

    it 'nothing filtered out' do
      expect(subject).to be true
    end
  end
end
