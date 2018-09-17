require 'spec_helper'

describe 'Excluding a path from running when' do
  subject { distributor.all_files.any? { |f| f.include? banished_dir } }

  let(:banished_dir) { '/features/' }
  let(:file_pattern) { 'spec/**/*_spec.rb' } # The hardcoded pattern for rspec boosters
  let(:distributor) { TestBoosters::Files::Distributor.new(nil, file_pattern, 12) }

  after do
    ENV.delete('SEMAPHORE_TRIGGER_SOURCE')
    ENV.delete('BRANCH_NAME')
  end

  context 'on a core branch' do
    before { ENV['BRANCH_NAME'] = 'master' }

    it 'files filtered out correctly' do
      expect(subject).to be true
    end
  end

  context 'on an arbitrary branch' do
    before { ENV['BRANCH_NAME'] = 'abracadabra' }

    it 'files filtered out correctly' do
      expect(subject).to be false
    end
  end

  context 'when manually rebuilt' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'manual' }

    it 'files filtered correctly' do
      expect(subject).to be true
    end
  end

  context 'an automated push' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'push' }

    it 'files filtered correctly' do
      expect(subject).to be false
    end
  end

  context 'nothing is specified' do
    it 'features filtered out' do
      expect(subject).to be false
    end
  end
end
