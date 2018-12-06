module TestBoosters
  class Job

    def self.run(command, known_files, leftover_files)
      new(command, known_files, leftover_files).run
    end

    def initialize(command, known_files, leftover_files)
      @command = command
      @known_files = known_files
      @leftover_files = leftover_files
    end

    def display_header
      puts
      TestBoosters::Shell.display_files("Known files for this job", @known_files)
      TestBoosters::Shell.display_files("Leftover files for this job", @leftover_files)

      puts "=" * 80
      puts ""
    end

    def files
      @all_files ||= @known_files + @leftover_files
    end

    def rerun_files
      return "" unless rerun_files_exist?
      File.open("tmp/capybara/rspec_rerun.txt", "r").read
    end

    def rerun_files_exist?
      File.exist?("tmp/capybara/rspec_rerun.txt")
    end

    def crystalball_glowing?
      File.exist?('tmp/crystal_files.txt')
    end

    def split_crystal_files
      all_specs = File.open('tmp/crystal_files.txt') { |f| f.read }.split(' ')
      # These ENV vars are set by us in project settings, we can work out how many rspec threads there are
      num_threads = ENV['FIRST_CUKE_JOB_ID'].to_i - ENV['FIRST_RSPEC_JOB_ID'].to_i
      my_thread = ENV['SEMAPHORE_CURRENT_JOB'].to_i - ENV['FIRST_RSPEC_JOB_ID'].to_i

      # Figure out how many scenarios to assign to each thread
      specs_per_thread = all_specs.length / num_threads

      # In the case there's more workers than problems, assign with a 1-to-1 ratio as many times as we can
      if num_threads > all_specs.length
        return (my_thread + 1) > all_specs.length ? [] : [all_specs[my_thread]]
      end

      # If i'm not the last thread
      if my_thread < num_threads - 1
        my_specs = all_specs[(my_thread * specs_per_thread)..((my_thread + 1) * specs_per_thread - 1)]
      else
        my_specs = all_specs[(my_thread * specs_per_thread)..-1]
      end

      my_specs
    end

    def run
      display_header

      if files.empty?
        puts("No files to run in this job!")

        return 0
      end

      # Check if we're running crystalball, update our allocated files if so
      if crystalball_glowing? then
        files = split_crystal_files
      end

      # Cucumber CL arguments handle the re-running
      if @command.include?("cucumber")
        TestBoosters::Shell.execute("#{@command} --strict -f rerun --out rerun.txt #{files.join(" ")} || #{@command} --strict @rerun.txt")

      # Re-run rspec tests marked as failed
      elsif @command.include?("rspec")
        exit_status = TestBoosters::Shell.execute("#{@command} #{files.join(" ")}")
        return exit_status unless rerun_files_exist?

        # Some scenarios were marked for re-run, so return the result of our second pass
        TestBoosters::Shell.execute("#{@command} #{rerun_files}")

      # Running Go / minitest etc - no re-runs
      else
        TestBoosters::Shell.execute("#{@command} #{files.join(" ")}")
      end
    end
  end
end
