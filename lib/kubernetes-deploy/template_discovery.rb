# frozen_string_literal: true
module KubernetesDeploy
  class TemplateDiscovery
    class << self
      def templates(template_paths)
        templates = {}
        dir_paths = template_paths.select { |path| File.directory?(path) }
        file_paths = template_paths.select { |path| File.file?(path) }

        # Directory paths
        dir_paths.each_with_object(templates) do |template_dir, hash|
          hash[template_dir] = Dir.foreach(template_dir).select do |filename|
            filename.end_with?(".yml.erb", ".yml", ".yaml", ".yaml.erb")
          end
        end
        # Filename paths
        file_paths.each_with_object(templates) do |filename, hash|
          dir_name = File.dirname(filename)
          hash[dir_name] ||= []
          hash[dir_name] << File.basename(filename) unless hash[dir_name].include?(filename)
        end

        templates
      end

      def validate_templates(template_paths)
        file_regex = /(\.ya?ml(\.erb)?)$|(secrets\.ejson)$/
        errors = []
        template_paths.each do |path|
          if !File.directory?(path) && !File.file?(path)
            errors << "Template does not exist. Couldn't find file or directory #{path}"
          elsif File.directory?(path) && Dir.entries(path).none? { |file| file =~ file_regex }
            errors << "`#{path}` doesn't contain valid templates (secrets.ejson or postfix .yml, .yml.erb)"
          end
        end
        errors
      end
    end
  end
end
