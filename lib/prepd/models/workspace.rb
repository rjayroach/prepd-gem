module Prepd
  class Workspace < Base
    attr_accessor :name, :type

    before_validation :set_defaults

    validates :name, presence: true
    validate :directory_cannot_exist

    after_create :create_workspace, :initialize_workspace

    def set_defaults
      self.type ||= 'standard'
      self.name = 'share' if self.type.eql?('shared')
    end

    def directory_cannot_exist
      return if Prepd.config.force
      errors.add(:directory_exists, requested_dir) if Dir.exists?(requested_dir)
    end

    def requested_dir
      "#{Prepd.config.working_dir}/#{name}"
    end

    def create_workspace
      Dir.chdir(Prepd.config.working_dir) do
        FileUtils.rm_rf(name) if Prepd.config.force
        FileUtils.mkdir_p(name)
      end
    end

    def initialize_workspace
      Dir.chdir(requested_dir) do
        initialize_standard_workspace if type.eql?('standard')
        initialize_shared_workspace if type.eql?('shared')
      end
    end

    # Copy only artifiacts necessary for a shared workspace
    def initialize_shared_workspace
      File.open('prepd-workspace.yml', 'w') { |f| f.write("---\nname: #{name}\n") }
      %w(projects machines developer/machines).each do |dir|
        FileUtils.mkdir_p(dir)
        FileUtils.cp_r("#{Prepd.files_dir}/workspace/#{dir}/.", dir)
      end
    end

    def initialize_standard_workspace
      FileUtils.cp_r("#{Prepd.files_dir}/workspace/.", '.')
      Prepd.register_workspace(Dir.pwd)
      Dir.chdir('developer') do
        File.open('vars.yml', 'w') do |f|
          f.puts("---\ngit_user:")
          f.puts("  name: #{`git config --get user.name`.chomp}")
          f.puts("  email: #{`git config --get user.email`.chomp}")
        end
        Prepd.write_password_file('vault-password.txt')
        FileUtils.touch('vault.yml')
        system('ansible-vault encrypt vault.yml')
      end
    end
  end
end
