require 'spec_helper'

describe 'Excluding a path from running when' do
  subject(:test_files_present) { distributor.all_files.any? { |f| f.include? banished_dir } }

  let(:banished_dir) { '/integration/' } # The regression path were going to test filtering out
  let(:file_pattern) { 'spec/**/*_spec.rb' } # The hardcoded pattern for rspec boosters
  let(:distributor) { TestBoosters::Files::Distributor.new(nil, file_pattern, 12) }

  before do
    ENV['EXEMPT_BRANCHES'] = 'master,develop,release'
    ENV['REGRESSION_PATH'] = 'spec/integration/'
    ENV['COMMIT_FILTER'] = '' # This ENV var is only used in this spec, to stub the git log
  end

  after do
    ENV.delete('SEMAPHORE_TRIGGER_SOURCE')
    ENV.delete('BRANCH_NAME')
  end

  context 'on an exempt branch' do
    before { ENV['BRANCH_NAME'] = 'master' }

    it 'with regression path' do
      expect(test_files_present).to be true
    end

    it 'without regression path' do
      ENV.delete('REGRESSION_PATH')
      expect(test_files_present).to be true
    end
  end

  context 'on an arbitrary branch' do
    before { ENV['BRANCH_NAME'] = 'abracadabra' }

    it 'with regression path' do
      expect(test_files_present).to be false
    end

    it 'without regression path' do
      ENV.delete('REGRESSION_PATH')
      expect(test_files_present).to be true
    end
  end

  context 'when manually rebuilt' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'manual' }

    it 'without branch specified' do
      expect(test_files_present).to be true
    end

    it 'on arbitrary branch' do
      ENV['BRANCH_NAME'] = 'abracadabra'
      expect(test_files_present).to be true
    end
  end

  context 'an automated push' do
    before { ENV['SEMAPHORE_TRIGGER_SOURCE'] = 'push' }

    it 'without branch specified' do
      expect(test_files_present).to be false
    end

    it 'on an exempt branch' do
      ENV['BRANCH_NAME'] = 'develop'
      expect(test_files_present).to be true
    end
  end

  context 'all environment variables' do
    it 'deleted' do
      ENV.clear
      ENV['COMMIT_FILTER'] = ''

      expect(test_files_present).to be true
    end

    it 'with empty strings' do
      ENV['EXEMPT_BRANCHES'] = ''
      ENV['REGRESSION_PATH'] = ''
      ENV['SEMAPHORE_TRIGGER_SOURCE'] = ''
      ENV['BRANCH_NAME'] = ''

      expect(test_files_present).to be true
    end
  end

  context '[regression]' do
    before { ENV['COMMIT_FILTER'] = '[regression]' }

    it 'shouldnt filter out anything' do
      expect(test_files_present).to be true
    end

    context 'and [specs off]' do
      before { ENV['COMMIT_FILTER'] = '[regression]...[specs off]' }

      it 'should filter out all specs' do
        expect(test_files_present).to be false
      end
    end
  end

  context '[specs off]' do
    before { ENV['COMMIT_FILTER'] = '[specs off]' }

    it 'should filter out specs' do
      expect(test_files_present).to be false
    end
  end

  context '[cukes off]' do
    before { ENV['COMMIT_FILTER'] = '[cukes off]' }

    it 'should add .feature to ignore path' do
      expect(distributor.env_handler).to include '.feature'
    end
  end
end

# This stubs the `git log -1` call in distributor.rb
# This spec requires COMMIT_FILTER to have a value, however if it doesn't exist
# during production/operation that's fine, it's only used here.
module Kernel
  def `(command)
    ENV['COMMIT_FILTER']
  end
end
