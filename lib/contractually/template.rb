module Contractually
  class Template
    attr_accessor :template_id

    def initialize(api, template_id)
      @api = api
      self.template_id = template_id
    end

    def fields
      response = @api.get("/templates/#{template_id}/fields")
      raise "Could not fetch template fields: #{response.body}" unless response.code == 201

      JSON.parse(response.body)
    end
  end
end
