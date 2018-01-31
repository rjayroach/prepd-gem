module Prepd
  class Project < NewObject
    def create
      setup_git
    end

    def setup
      Dir.chdir("#{project.path}/ansible") do
        FileUtils.cp_r('application', name)
      end
    end

    #
    # Clone prepd-project, remove the git history and start with a clean repository
    #
    def setup_git
      system('git clone git@github.com:rjayroach/prepd-project.git .')
      FileUtils.rm_rf('.git')
      system('git init')
      system('git add .')
      system("git commit -m 'First commit from Prepd'")
    end
  end
end
