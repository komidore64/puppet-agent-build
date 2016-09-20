require 'yaml'
require 'tempfile'
require 'nokogiri'
require 'fileutils'

$beaker_jobs = []
$completed_jobs = {}

task :machines do

  unless system('klist')
    puts 'No kerberos ticket found. Exiting.'
    exit 1
  end

  matrix = YAML.load_file("beaker_matrix.yaml")

  matrix.each do |family, arches|
    arches.each do |arch|
      request_machine(family, arch)
    end
  end

  until $beaker_jobs.empty?
    store_when_available($beaker_jobs)
    sleep 5
  end
end

task :puppet_build => [:machines] do
  ssh_known_hosts
  begin
    ansible_hosts = $completed_jobs.values.map { |str| str += " ansible_user=root" }
    build_inventory = <<END_OF_INVENTORY
[build_host]
    #{ansible_hosts.join("\n")}

[localhost]
localhost ansible_connections=local
END_OF_INVENTORY

    tempfile = Tempfile.open("build_inventory")
    tempfile.write(build_inventory)
    tempfile.close

    sleep 5 # hax
    `ansible-playbook -i #{tempfile.path} prep_box.yaml`
  ensure
    tempfile.unlink
    cleanup_ssh_known_hosts
  end
end
