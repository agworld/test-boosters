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

    def rspec_rerun
      rerun_files = ''
      File.open('rspec_rerun.txt') do |f|
        f.each_line { |line| rerun_files += line unless line.nil? }
      end
      rerun_files
    rescue Errno::ENOENT
      '' # Return empty string
    end

    def run
      display_header

      if files.empty?
        puts("No files to run in this job!")

        return 0
      end

      if @command.include?('cucumber')
        TestBoosters::Shell.execute("#{@command} --strict -f rerun --out rerun.txt #{files.join(' ')} || #{@command} --strict @rerun.txt")
      elsif @command.include?('rspec')
        exit_status = TestBoosters::Shell.execute("#{@command} #{files.join(" ")}")
        rspec_rerun.empty? ? exit_status : TestBoosters::Shell.execute("#{@command} #{rspec_rerun}")
      else
        TestBoosters::Shell.execute("#{@command} #{files.join(" ")}")
      end
    end
  end
end
