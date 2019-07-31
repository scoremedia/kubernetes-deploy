# frozen_string_literal: true

module KubernetesDeploy
  module OptionsHelper
    class OptionsError < StandardError; end

    STDIN_TEMP_FILE = "from_stdin.yml.erb"
    class << self
      def with_validated_template_dirs(template_dirs)
        dirs = []
        if template_dirs.empty?
          dirs << default_template_dir
        else
          template_dirs.uniq!
          template_dirs.each do |template_dir|
            next if template_dir == '-'
            dirs << template_dir
          end
        end

        if template_dirs.include?("-")
          Dir.mktmpdir("kubernetes-deploy") do |dir|
            template_dir_from_stdin(temp_dir: dir)
            dirs << dir
            yield dirs
          end
        else
          yield dirs
        end
      end

      private

      def default_template_dir
        template_dir = if ENV.key?("ENVIRONMENT")
          File.join("config", "deploy", ENV['ENVIRONMENT'])
        end

        if !template_dir || template_dir.empty?
          raise OptionsError, "Template directory is unknown. " \
            "Either specify --template-dir argument or set $ENVIRONMENT to use config/deploy/$ENVIRONMENT " \
            "as a default path."
        end

        template_dir
      end

      def template_dir_from_stdin(temp_dir:)
        File.open(File.join(temp_dir, STDIN_TEMP_FILE), 'w+') { |f| f.print($stdin.read) }
      rescue IOError, Errno::ENOENT => e
        raise OptionsError, e.message
      end
    end
  end
end
