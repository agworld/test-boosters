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

    def run
      display_header

      if files.empty?
        puts("No files to run in this job!")

        return 0
      end

      # TODO: do this properly, hack this in for now to get it working
      if @command =~ /cucumber/
        cmd = "[ ${CUKES_OFF:-0} -eq 1 ] || ( bundle exec cucumber --strict -f rerun --out rerun.txt #{files.join(" ")} || bundle exec cucumber --strict @rerun.txt; fi" )
        TestBoosters::Shell.execute(cmd)
      else
        TestBoosters::Shell.execute("#{@command} #{files.join(" ")}")
      end
    end

  end
end
