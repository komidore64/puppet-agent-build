module PuppetAgentBuild
  class CLI
    class << self
      def run(argv = ARGV)
        options = parse_options(argv)
        # do more stuff
      end

      private

      def parse_options(argv)
        options = {}
        OptionParser.new do |opts|
          opts.on("--ansible-args ARGS", "Any command line arguments desired to be sent to Ansible.") do |ansible_args|
            options[:ansible_args] = ansible_args
          end

          opts.on("--verbose", "-v", "Verbose output") do
            options[:verbose] = true
          end

          opts.on("--quiet", "Supress all output") do
            options[:quiet] = true
          end
        end.parse!(argv)
        options
      end
    end
  end
end
