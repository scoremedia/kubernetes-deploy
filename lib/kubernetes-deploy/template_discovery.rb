# frozen_string_literal: true

module KubernetesDeploy
  class TemplateDiscovery
    def initialize(template_dirs)
      @template_dirs = template_dirs
    end

    def templates
      @template_dirs.each_with_object({}) do |template_dir, hash|
        hash[template_dir] = Dir.foreach(template_dir).select do |filename|
          filename.end_with?(".yml.erb", ".yml", ".yaml", ".yaml.erb")
        end
      end
    end
  end
end
