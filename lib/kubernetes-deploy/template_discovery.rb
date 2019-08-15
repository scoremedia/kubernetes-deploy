# frozen_string_literal: true
module KubernetesDeploy
  class TemplateDiscovery
    class << self
      def templates(template_args)
        template_dirs = {}
        dir_args = template_args.select { |arg| File.directory?(arg) }
        file_args = template_args.select { |arg| File.file?(arg) }

        # Directory arg
        dir_args.each_with_object(template_dirs) do |template_dir, hash|
          hash[template_dir] = Dir.foreach(template_dir).select do |filename|
            filename.end_with?(".yml.erb", ".yml", ".yaml", ".yaml.erb")
          end
        end
        # Filename arg
        file_args.each_with_object(template_dirs) do |filename, hash|
          dir_name = File.dirname(filename)
          hash[dir_name] ||= []
          hash[dir_name] << File.basename(filename) unless hash[dir_name].include?(filename)
        end

        template_dirs
      end

      def validate_templates(template_args)
        file_regex = /(\.ya?ml(\.erb)?)$|(secrets\.ejson)$/
        errors = []
        template_args.each do |arg|
          if !File.directory?(arg) && !File.file?(arg)
            errors << "Template does not exist. Couldn't find file or directory #{arg}"
          elsif File.directory?(arg) && Dir.entries(arg).none? { |file| file =~ file_regex }
            errors << "`#{arg}` doesn't contain valid templates (secrets.ejson or postfix .yml, .yml.erb)"
          end
        end
        errors
      end
    end
  end
end
