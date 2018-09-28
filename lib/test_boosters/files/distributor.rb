module TestBoosters
  module Files

    #
    # Distributes test files based on split configuration, file pattern, and their file size
    #
    class Distributor

      def initialize(split_configuration_path, file_pattern, job_count)
        @split_configuration_path = split_configuration_path
        @file_pattern = file_pattern
        @job_count = job_count
        @exclude_path = []

        env_handler
      end

      def env_handler
        last_msg = `git log -1`
        regression_path = ENV['REGRESSION_PATH']
        source = ENV['SEMAPHORE_TRIGGER_SOURCE']
        current_branch = ENV['BRANCH_NAME']
        exempt_branches =
         if ENV['EXEMPT_BRANCHES'].nil?
           []
         else
           ENV['EXEMPT_BRANCHES'].split(',')
        end

        @exclude_path << regression_path unless exempt_branches.include?(current_branch)
        if source.eql?('manual')
          @exclude_path.delete(regression_path)
        end
        if last_msg.include?('[regression]')
          @exclude_path.delete(regression_path)
        end
        if last_msg.include?('[cukes off]')
          @exclude_path << '.feature'
        end
        if last_msg.include?('[specs off]')
          @exclude_path << '_spec.rb'
        end
        if last_msg.include?('[minitest off]')
          @exclude_path << '_test.rb'
        end
        if last_msg.include?('[exunit off]')
          @exclude_path << '_test.exs'
        end
        if last_msg.include?('[gotest off]')
          @exclude_path << '_test.go'
        end

        @exclude_path
      end

      def display_info
        puts "Split configuration present: #{split_configuration.present? ? "yes" : "no"}"
        puts "Split configuration valid: #{split_configuration.valid? ? "yes" : "no"}"
        puts "Split configuration file count: #{split_configuration.all_files.size}"
        puts "Paths filtered out: #{@exclude_path}"
      end

      def files_for(job_index)
        known    = all_files & split_configuration.files_for_job(job_index)
        leftover = leftover_files.select(:index => job_index, :total => @job_count)

        [known, leftover]
      end

      def all_files
        return Dir[@file_pattern].sort if @exclude_path.all? { |path| path.nil? || path.empty? }
        Dir[@file_pattern].sort.reject do |path|
          @exclude_path.any? { |word| path.include?(word) unless word.nil? || word.empty? }
        end
      end

      private

      def leftover_files
        @leftover_files ||= TestBoosters::Files::LeftoverFiles.new(all_files - split_configuration.all_files)
      end

      def split_configuration
        @split_configuration ||= TestBoosters::Files::SplitConfiguration.new(@split_configuration_path, @exclude_path)
      end

    end

  end
end
