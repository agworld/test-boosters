module TestBoosters
  module Boosters
    class Base

      def initialize(file_pattern, split_configuration_path, command, exclude_path)
        @command = command
        @file_pattern = file_pattern
        @split_configuration_path = split_configuration_path
        @exclude_path = exclude_path
      end

      # :reek:TooManyStatements
      def run
        display_header

        before_job # execute some activities when the before the job starts

        distribution.display_info

        known, leftover = distribution.files_for(job_index)

        exit_status = TestBoosters::Job.run(@command, known, leftover)

        after_job # execute some activities when the job finishes

        exit_status
      end

      def before_job
        # Do nothing
      end

      def after_job
        # Do nothing
      end

      def display_header
        version = "Test Booster v#{TestBoosters::VERSION}"
        job_info = "Job #{job_index + 1} out of #{job_count}"

        TestBoosters::Shell.display_title("#{version} - #{job_info}")
      end

      def distribution
        @distribution ||= TestBoosters::Files::Distributor.new(@split_configuration_path,
                                                               @file_pattern,
                                                               job_count,
                                                               @exclude_path)
      end

      def job_index
        @job_index ||= cli_options[:job_index] - 1
      end

      def job_count
        @job_count ||= cli_options[:job_count]
      end

      private

      def cli_options
        @cli_options ||= TestBoosters::CliParser.parse
      end

    end
  end
end
