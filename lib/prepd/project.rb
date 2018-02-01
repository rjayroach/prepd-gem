module Prepd
  class Project < NewObject
    def create
      setup_git
    end

    def repository
      :project
    end

    def repository_version
      '0.1.1'
    end
  end
end
