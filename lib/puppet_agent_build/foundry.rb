require 'nokogiri'
require 'pty'

module PuppetAgentBuild
  class Foundry

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
      sleep 30 # sometimes the boxes are a little slow to get an IP address

      prep
    end

    def ansible
      ansible_prep_boxes
      ansible_build
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
      job_id = ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")

      job = Job.new(job_id, family, arch)
      @jobs << job
      puts "#{job} --> #{job.id}"
    end

    def return_boxes
      @jobs.each do |job|
        return_box(job)
      end
    end

    def return_box(job)
      hostname = job.host
      cmd = "bkr system-release '#{hostname}'"
      ret = shell(cmd)
      puts "#{hostname} returned to beaker"
      @jobs -= [ job ]
    end

    def watch_jobs
      until running_jobs.empty?
        running_jobs.each do |job|
          check_job(job)
          sleep 5
        end
      end
    end

    def check_job(job)
      ret = Nokogiri::Slop(shell("bkr job-results #{job.id}")) # nokogiri told me to never use slop ... ¯\_(ツ)_/¯

      job.last_status = ret.job["status"].downcase
      system = ret.job.recipeSet.recipe['system']
      case job.last_status
      when "reserved"
        job.host = system
        reserved(job)
      when "completed"
        completed(job)
      when "aborted","cancelled"
        killed(job)
      else
        puts "#{job.id} : #{job.last_status}"
      end
    end

    def reserved(job)
      puts "#{job} is reserved (#{jobs_left}) => #{job.host}"
      # don't remove a job once it's reserved
    end

    def completed(job)
      puts "#{job} has completed prematurely. requesting another..."
      request_box(job.family, job.arch)
      @jobs -= [ job ]
    end

    def killed(job)
      puts "#{job} has been #{job.last_status}. removing..."
      @jobs -= [ job ]
    end

    def jobs_left
      "#{@jobs.select { |job| job.last_status == "reserved" }.size} of #{@jobs.size}"
    end

    def running_jobs
      @jobs.select { |job| job.last_status != "reserved" }
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

      build_host_lines = @jobs.map do |job|
        "#{job.host} ansible_user=root el_version=#{job.version} el_arch=#{job.arch}\n"
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
      @jobs.map { |job| job.host }
    end

    def prep_known_hosts
      @jobs.each do |job|
        keys = `ssh-keyscan #{job.host}`
        File.open(known_hosts_filepath, "a") do |file|
          file.puts(keys)
        end
        job.keys = keys.split("\n")
      end
    end

    def clean_known_hosts
      shell("cp #{known_hosts_filepath} #{known_hosts_filepath}.backup")
      known_hosts = []

      File.foreach(known_hosts_filepath) do |line|
        known_hosts << line.strip
      end

      @jobs.each do |job|
        known_hosts -= job.keys
      end

      File.open(known_hosts_filepath, "w") do |file|
        file.write(known_hosts.join("\n"))
      end
      shell("rm #{known_hosts_filepath}.backup")
    end

    def inventory_filepath
      File.join(INVENTORY_DIR, 'inventory.ini')
    end

    def known_hosts_filepath
      "/home/#{ENV['USER']}/.ssh/known_hosts"
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
  end # class Foundry
end # module PuppetAgentBuild
