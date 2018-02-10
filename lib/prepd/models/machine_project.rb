module Prepd
  class MachineProject < ActiveRecord::Base
    belongs_to :machine
    belongs_to :project

    validates :project_id, uniqueness: { scope: :machine_id }
  end
end
