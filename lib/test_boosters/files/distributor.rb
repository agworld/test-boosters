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
        if last_msg.include?('[spec off]')
          @exclude_path << '_spec.rb'
        end
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
        is_valid = lambda { |x| x.nil? || x.empty? }

        return Dir[@file_pattern].sort if @exclude_path.all? { |path| is_valid[path] }
        Dir[@file_pattern].sort.reject do |path|
          @exclude_path.any? { |word| path.include?(word) unless is_valid[word] }
        end
      end

      private

      def leftover_files
        @leftover_files ||= TestBoosters::Files::LeftoverFiles.new(all_files - split_configuration.all_files)
      end

      def split_configuration
        @split_configuration ||= TestBoosters::Files::SplitConfiguration.new(@split_configuration_path)
      end

    end

  end
end
