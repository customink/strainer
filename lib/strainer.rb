require 'strainer/color'
require 'strainer/runner'
require 'strainer/sandbox'

module Strainer
  def self.root
    @@root ||= File.expand_path('../../', __FILE__)
  end
end
