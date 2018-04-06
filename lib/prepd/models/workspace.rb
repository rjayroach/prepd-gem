module Prepd
  class Workspace < Base
    attr_accessor :name

    validates :name, presence: true
    validate :directory_cannot_exist

    after_create :create_workspace, :initialize_workspace

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
        File.open('prepd-workspace.yml', 'w') { |f| f.write("---\nname: #{name}\n") }
        FileUtils.cp_r("#{Prepd.files_dir}/workspace/.", '.')
        Dir.chdir('developer') do
          File.open('clusters/vars.yml', 'w') do |f|
            f.puts("---\ngit_user:")
            f.puts("  name: #{`git config --get user.name`.chomp}")
            f.puts("  email: #{`git config --get user.email`.chomp}")
          end
          Prepd.write_password_file('vault-password.txt')
          FileUtils.touch('clusters/credentials.yml')
          system('ansible-vault encrypt clusters/credentials.yml')
        end
        # NOTE: remove after testing
        # Dir.chdir('machines') do
        #   FileUtils.mkdir('packer_cache')
        #   Dir.chdir('packer_cache') do
        #     FileUtils.cp('/tmp/50e697ab8edda5b0ac5ba2482c07003d2ff037315c7910af66efd3c28d23ed51.iso', '.')
        #   end
        # end
      end
    end
  end
end
