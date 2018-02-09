module Prepd
  class MachineProject < ActiveRecord::Base
    belongs_to :machine
    belongs_to :project
  end
end
