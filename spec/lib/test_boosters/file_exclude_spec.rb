require 'spec_helper'

describe 'Excluding a path from running when' do
  subject { distributor.all_files.any? { |f| f.include? banished_dir } }

  let(:banished_dir) { '/integration/' } # The regression path were going to test filtering out
  let(:file_pattern) { 'spec/**/*_spec.rb' } # The hardcoded pattern for rspec boosters
  let(:distributor) { TestBoosters::Files::Distributor.new(nil, file_pattern, 12) }

  before do
    ENV['EXEMPT_BRANCHES'] = 'master,develop,release'
    ENV['REGRESSION_PATH'] = 'spec/integration/'
  end

  after do
    ENV.delete('SEMAPHORE_TRIGGER_SOURCE')
    ENV.delete('BRANCH_NAME')
  end

  context 'on an exempt branch' do
    before { ENV['BRANCH_NAME'] = 'master' }

    it 'with regression path' do
      expect(subject).to be true
    end

    it 'without regression path' do
      ENV.delete('REGRESSION_PATH')
      expect(subject).to be true
    end
  end

  context 'on an arbitrary branch' do
    before { ENV['BRANCH_NAME'] = 'abracadabra' }

    it 'with regression path' do
      expect(subject).to be false
    end

    it 'without regression path' do
      ENV.delete('REGRESSION_PATH')
      expect(subject).to be true
    end
  end

  context 'when manually rebuilt' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'manual' }

    it 'without branch specified' do
      expect(subject).to be true
    end

    it 'on arbitrary branch' do
      ENV['BRANCH_NAME'] = 'abracadabra'
      expect(subject).to be true
    end
  end

  context 'an automated push' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'push' }

    it 'without branch specified' do
      expect(subject).to be false
    end

    it 'on an exempt branch' do
      ENV['BRANCH_NAME'] = 'develop'
      expect(subject).to be true
    end
  end

  context 'all environment variables' do
    it 'deleted' do
      ENV.clear
      expect(subject).to be true
    end

    it 'with empty strings' do
      ENV['EXEMPT_BRANCHES'] = ''
      ENV['REGRESSION_PATH'] = ''
      ENV['SEMAPHORE_TRIGGER_SOURCE'] = ''
      ENV['BRANCH_NAME'] = ''

      expect(subject).to be true
    end
  end
end
