module Strainer
  class CLI
    def self.run(*cookbooks)
      @sandbox = Strainer::Sandbox.new(cookbooks)
      @runner = Strainer::Runner.new(@sandbox)
    end
  end
end
