require 'nokogiri'
require 'pty'

module PuppetAgentBuild
  class SRPMFoundry

    RESERVATION_TIME = 356400 # in seconds; == 99 hours
    MINIMUM_MEMORY = 1024 # in megabytes

    def initialize(beaker_machine_matrix)
      @matrix = beaker_machine_matrix
    end

    def start
      raise 'no kerberos ticket found' unless system('klist') # bail early

      request_boxes
      watch_jobs
      prep
      ansible_prep_boxes
      ansible_build
      cleanup
    end

    private

    def request_boxes
      @jobs = []
      @matrix.each do |family, arches|
        arches.each do |arch|
          job = request_box(family, arch)
          next if job.nil?
          puts "#{family}:#{arch} --> #{job}"
          @jobs << [ job, versionify(family), arch ]
        end
      end
    end

    def request_box(family, arch)
      cmd = "bkr workflow-simple " +
        "--family #{family} " +
        "--task /distribution/install " +
        "--reserve --reserve-duration #{RESERVATION_TIME} " +
        "--arch #{arch} " +
        (family.include?('5') ? '' : '--variant Server ') +
        "--hostrequire='memory > #{MINIMUM_MEMORY}'"
      ret = shell(cmd, :error_on_nonzero => false)
      return nil if $?.to_i != 0

      # there's some weirdness going on here with a delay. the first time ret
      # is accessed it's empty? maybe the shell hasn't returned it's output
      # quite yet?
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")

      # is that your final answer?
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
    end

    def watch_jobs
      @boxes = []
      until @jobs.empty?
        @jobs.each do |job, family, arch|
          ret = Nokogiri::Slop(shell("bkr job-results #{job}"))
          status = ret.job["status"]
          if status == "Reserved"
            system = ret.job.recipeSet.recipe['system']
            @jobs -= [ [ job, family, arch ] ]
            @boxes << [ system, family, arch ]
            puts "#{family}:#{arch} has completed (#{@boxes.size} of #{@jobs.size + @boxes.size}) => #{system}"
          else
            puts "#{job} : #{status}"
          end
          sleep 5 # don't ddos beaker
        end
      end
    end

    def prep
      prep_known_hosts
      generate_inventory
    end

    def ansible_prep_boxes
      fancy_shell("ansible-playbook -i #{inventory_filepath} prep_box.yaml 2>&1")
    end

    def ansible_build
      fancy_shell("ansible-playbook -i #{inventory_filepath} build.yaml 2>&1")
    end

    def generate_inventory
      FileUtils.rm(inventory_filepath) if File.exist?(inventory_filepath)

      build_host_lines = @boxes.map do |hostname, version, arch|
        "#{hostname} ansible_user=root el_version=#{version} el_arch=#{arch}\n"
      end

      File.open(inventory_filepath, "w") do |file|
        file.puts("[build_host]")
        file.write(build_host_lines.join(''))
        file.puts
        file.puts("[localhost]")
        file.puts("localhost ansible_connections=local")
      end
    end

    def only_hostnames
      @boxes.map { |i| i[0] }
    end

    def prep_known_hosts
      clean_known_hosts

      only_hostnames.each do |host|
        key = `ssh-keyscan #{host}`
        File.open(known_hosts_filepath, "a") do |file|
          file.puts(key)
        end
      end
    end

    def clean_known_hosts
      known_hosts = []

      File.foreach(known_hosts_filepath) do |line|
        known_hosts << line
      end

      only_hostnames.each do |hostname|
        ind = known_hosts.find_index { |line| line.include?(hostname) }
        known_hosts.delete_at(i) unless ind.nil?
      end

      File.open(known_hosts_filepath, "w") do |file|
        file.write(known_hosts.join(""))
      end
    end

    def inventory_filepath
      File.join(File.dirname(File.expand_path(__FILE__)), 'inventory.ini')
    end

    def known_hosts_filepath
      "/home/#{ENV['USER']}/.ssh/known_hosts"
    end

    def versionify(family)
      case family
      when /5/
        5
      when /6/
        6
      when /7/
        7
      else
        raise "you suck"
      end
    end

    def shell(cmd, options = {})
      options = { :error_on_nonzero => true }.merge(options)
      ret = `#{cmd}`
      raise "Non-zero exit status from [ #{cmd} ]." if !$?.to_i.zero? && options[:error_on_nonzero]
      ret
    end

    def fancy_shell(cmd)
      begin
        PTY.spawn(cmd) do |stdout, stdin, pid|
          begin
            stdout.each { |line| print line }
          rescue Errno::EIO
            # do nothing
          end
        end
      rescue PTY::ChildExited
        put "The child process [ #{cmd} ] exited."
      ensure
        raise "Non-zero exit status from [ #{cmd} ]." unless $?.to_i.zero?
      end
    end
  end # class SRPMFoundry
end # module PuppetAgentBuild
