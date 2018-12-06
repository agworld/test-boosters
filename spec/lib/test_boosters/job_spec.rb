require "spec_helper"
require 'byebug'

describe TestBoosters::Job do

  before do
    allow(TestBoosters::Shell).to receive(:execute).and_return(12)
    allow(TestBoosters::Shell).to receive(:display_files)
  end

  def run
    described_class.run("bundle exec rspec", ["file1.rb"], ["file2.rb"])
  end

  describe ".run" do
    it "displays known files" do
      expect(TestBoosters::Shell).to receive(:display_files).with("Known files for this job", ["file1.rb"])
      run
    end

    it "displays leftover files" do
      expect(TestBoosters::Shell).to receive(:display_files).with("Leftover files for this job", ["file2.rb"])
      run
    end

    it "returns the commands exit status" do
      exit_status = run

      expect(exit_status).to eq(12)
    end

    context "no files" do
      it "returns 0 exit status" do
        exit_status = described_class.run("bundle exec rspec", [], [])

        expect(exit_status).to eq(0)
      end

      it "displays no files to run" do
        expect { described_class.run("bundle exec rspec", [], []) }.to output(/No files to run in this job!/).to_stdout
      end
    end
  end

  describe 'split_crystal_files' do
    subject(:split) { job.split_crystal_files }

    let(:job) { described_class.new(nil, nil, nil) }
    let(:files) { ['file_a.rb', 'file_b.rb', 'file_c.rb', 'file_d.rb', 'file_e.rb'] }

    before do
      allow_any_instance_of(File).to receive(:read).and_return(files.join(' '))

      set_cuke_job_id(15)
      set_rspec_job_id(10)
      set_current_id(10)
    end

    context 'when there are no files' do
      before { allow_any_instance_of(File).to receive(:read).and_return('') }

      it 'should not assign files' do
        expect(split).to be_empty
      end
    end

    context "when there's less workers than files" do
      before { set_cuke_job_id(12) }

      it 'allocates first worker less' do
        expect(split).to eq(files[0..1])
      end

      it 'allocates last worker leftovers' do
        set_current_id(11)
        expect(split).to eq(files[2..4])
      end
    end

    context "when there's more workers than files" do
      before { set_cuke_job_id(20) }

      it 'allocates first file to first thread' do
        set_current_id(10)
        expect(split).to eq([files.first])
      end

      it 'allocates one file to earlier threads' do
        set_current_id(14)
        expect(split).to eq([files.last])
      end

      it 'allocates nothing to later threads' do
        set_current_id(15)
        expect(split).to be_empty
      end
    end

    context 'in a standard use case' do
      # Using between 40 - 60 files
      # Using between 5 - 10 workers
      # Ensure all files are assigned
      let(:random) { Random.new }
      let(:num_workers) { random.rand(5..10) }
      let!(:files) do
        files = []
        random.rand(40..60).times { files << SecureRandom.hex(8) }
        files
      end

      before do
        set_rspec_job_id(0)
        set_cuke_job_id(num_workers)
      end

      it 'allocates ALL files' do
        allocated_files = []
        (0..num_workers).step(1) do |worker|
          set_current_id(worker)
          allocated_files += described_class.new(nil, nil, nil).split_crystal_files
        end

        expect(allocated_files - files).to be_empty
      end
    end
  end

  def set_cuke_job_id(id)
    ENV['FIRST_CUKE_JOB_ID'] = id.to_s
  end

  def set_rspec_job_id(id)
    ENV['FIRST_RSPEC_JOB_ID'] = id.to_s
  end

  def set_current_id(id)
    ENV['SEMAPHORE_CURRENT_JOB'] = id.to_s
  end
end
