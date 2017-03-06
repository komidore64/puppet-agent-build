module PuppetAgentBuild
  class Job
    attr_accessor :id, :family, :arch, :last_status, :host, :keys

    def initialize(id, family, arch)
      @id = id
      @family = family
      @arch = arch

      host = ""
      keys = []
    end

    def version
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

    def to_s
      "#{family}:#{arch}"
    end

  end
end
