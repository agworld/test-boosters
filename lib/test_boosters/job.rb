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
      if File.exist?('crystalball_run')
        ENV['CRYSTALBALL'] = true
        return true
      else
        return false
      end
    end

    def gather_code_coverage
      TestBoosters::Shell.execute("bundle exec rspec #{files.join(" ")}")
      # Coverage is in 'tmp/crystalball_data.yml'
      contents = File.read('tmp/crystalball_data.yml')
      puts contents
      # Need to upload it to an s3 bucket
      # Return true if all went well, else false
    end

    def run
      display_header

      if files.empty?
        puts("No files to run in this job!")

        return 0
      end

      # Check if we should run a crystalball coverage map
      if crystalball_glowing? then
        return gather_code_coverage
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
