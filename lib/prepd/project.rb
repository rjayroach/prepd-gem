module Prepd
  class Project < NewObject
    def create
      setup_git
    end

    #
    # Clone prepd-project, remove the git history and start with a clean repository
    #
    def setup_git
      Prepd.log('cloning git project') if config.verbose
      system('git clone git@github.com:rjayroach/prepd-project.git .') unless config.no_op
      Prepd.log('initializing new .git repository') if config.verbose
      FileUtils.rm_rf('.git') unless config.no_op
      system('git init') unless config.no_op
      Prepd.log('adding files to first commit') if config.verbose
      system('git add .') unless config.no_op
      system("git commit -m 'First commit from Prepd'") unless config.no_op
    end
  end
end
