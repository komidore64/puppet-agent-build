require 'yaml'
require 'nokogiri'

$beaker_jobs = []
$completed_jobs = []

namespace :beaker do

  task :machines do
    matrix = YAML.load_file("beaker_matrix.yaml")
    reservation_time = 356400 # in seconds; == 99 hours

    matrix.each do |family, arches|
      arches.each do |arch|
        variant = (family =~ /5/) ? '' : ' --variant Server'
        cmd = "bkr workflow-simple --family #{family} --task /distribution/install --reserve --reserve-duration #{reservation_time} --arch #{arch}" +
          variant

        ret = `#{cmd}`
        exit 1 if $?.to_i != 0

        # there's some weirdness going on here with a delay. the first time ret
        # is accessed it's empty? maybe the shell hasn't returned it's output
        # quite yet?
        ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
        ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
        ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
        ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")

        parsed_job = ret.strip.split.last.gsub(/\['(.*)'\]/, "#{$1}")
        puts "#{family}:#{arch} --> #{parsed_job}"
        $beaker_jobs << parsed_job
      end
    end

    until $beaker_jobs.empty?
      print_when_available($beaker_jobs)
      sleep 5
    end

    $completed_jobs.each do |j|
      puts Nokogiri::Slop(`bkr job-results #{j}`).job.recipeSet.recipe['system']
    end
  end

  def print_when_available(jobs)
    jobs.each do |j|
      status = Nokogiri::Slop(`bkr job-results #{j}`).job["status"]
      if status == "Reserved"
        puts "#{j} has completed"
        $beaker_jobs -= [j]
        $completed_jobs += [j]
      else
        puts "#{j} : #{status}"
      end
    end
  end
end

task :default => 'beaker:machines'
