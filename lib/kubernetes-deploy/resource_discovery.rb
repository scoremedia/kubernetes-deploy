# frozen_string_literal: true

module KubernetesDeploy
  class ResourceDiscovery
    def initialize(template_dirs:, namespace:, context:, current_sha:, logger:, bindings:, namespace_tags:, crds: {})
      @template_dirs = template_dirs
      @namespace = namespace
      @context = context
      @logger = logger
      @namespace_tags = namespace_tags
      @renderers = Hash.new do |hash, template_dir|
        hash[template_dir] = KubernetesDeploy::Renderer.new(
          current_sha: current_sha,
          template_dir: template_dir,
          logger: logger,
          bindings: bindings,
        )
      end
      @crds = crds
    end

    def resources
      resources = []
      templates.each do |template_dir, filenames|
        filenames.each do |filename|
          split_templates(template_dir, filename) do |r_def|
            crd = @crds[r_def["kind"]]&.first
            r = KubernetesResource.build(namespace: @namespace, context: @context, logger: @logger, definition: r_def,
              statsd_tags: @namespace_tags, crd: crd)
            resources << r
            @logger.info("  - #{r.id}")
          end
        end
      end
      resources
    end

    private

    def templates
      @template_dirs.each_with_object({}) do |template_dir, hash|
        hash[template_dir] = Dir.foreach(template_dir).select do |filename|
          filename.end_with?(".yml.erb", ".yml", ".yaml", ".yaml.erb")
        end
      end
    end

    def split_templates(template_dir, filename)
      file_content = File.read(File.join(template_dir, filename))
      rendered_content = @renderers[template_dir].render_template(filename, file_content)
      YAML.load_stream(rendered_content, "<rendered> #{filename}") do |doc|
        next if doc.blank?
        unless doc.is_a?(Hash)
          raise InvalidTemplateError.new("Template is not a valid Kubernetes manifest",
            filename: filename, content: doc)
        end
        yield doc
      end
    rescue InvalidTemplateError => err
      err.filename ||= filename
      raise err
    rescue Psych::SyntaxError => err
      raise InvalidTemplateError.new(err.message, filename: filename, content: rendered_content)
    end
  end
end
