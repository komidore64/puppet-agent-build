require 'nokogiri'
require 'pty'

module PuppetAgentBuild
  class SRPMFoundry

    RESERVATION_TIME = 356400 # in seconds; == 99 hours
    MINIMUM_MEMORY = 1024 # in megabytes

    def initialize(beaker_machine_matrix)
      raise 'no kerberos ticket found' unless system('klist') # bail early

      @matrix = beaker_machine_matrix
    end

    def run
      prep_for_ansible

      ansible_prep_boxes
      ansible_build
      shutdown
    end

    def prep_for_ansible
      request_boxes
      watch_jobs
      sleep 30 # sometimes the boxes are a little slow to get an ip addr

      prep
    end

    def shutdown
      clean_known_hosts
      return_boxes
    end

    private

    def request_boxes
      @jobs = []
      @matrix.each do |family, arches|
        arches.each do |arch|
          request_box(family, arch)
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
      return unless $?.to_i.zero?

      # there's some weirdness going on here with a delay. the first time ret
      # is accessed it's empty? maybe the shell hasn't returned it's output
      # quite yet?
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
      ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")

      # is that your final answer?
      job = ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")

      puts "#{family}:#{arch} --> #{job}"
      @jobs << [ job, family, arch ]
    end

    def return_boxes
      @boxes.each do |box|
        return_box(box)
      end
    end

    def return_box(box)
      hostname = box[0]
      cmd = "bkr system-release '#{hostname}'"
      ret = shell(cmd)
      puts "#{hostname} returned to beaker"
      @boxes -= box
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
            puts "#{family}:#{arch} is reserved (#{@boxes.size} of #{@jobs.size + @boxes.size}) => #{system}"
          elsif status == "Completed"
            puts "#{family}:#{arch} has completed prematurely. requesting another."
            request_box(family, arch) # ask for another box
            @jobs -= [ [ job, family, arch ] ] # remove the job that just completed
          else
            puts "#{job} : #{status}"
          end
          sleep 5
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

      build_host_lines = @boxes.map do |hostname, family, arch|
        "#{hostname} ansible_user=root el_version=#{versionify(family)} el_arch=#{arch}\n"
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
        known_hosts.delete_at(ind) unless ind.nil?
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
