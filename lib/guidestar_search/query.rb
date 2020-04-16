module GuidestarSearch
  class Query
    include HTTParty
    ssl_version :TLSv1_2

    attr_reader :parsed_response
    attr_reader :organizations
    attr_reader :total_num_organizations
    attr_reader :response

    def initialize(search_options)
      self.class.base_uri get_base_uri

      (page,per_page,search_options) = get_paging_options(search_options)

      @options = {
        basic_auth: {
          username: GuidestarSearch.configuration.api_key,
          password: ''
        },
        query: {
          # Convert the search_options hash into lucene query format
          q: search_options.map {|k, v| "#{k}:#{v}"}.join(' AND ')
        }
      }
      if page
        @options[:query][:p] = page
      end
      if per_page
        @options[:query][:r] = per_page
      end
    end

    def execute
      @response = self.class.get('/search.json', @options)
      @parsed_response = @response.parsed_response

      @total_num_organizations = if @parsed_response['total_hits']
        @parsed_response['total_hits'].to_i
      else
        0
      end

      @organizations = if @parsed_response['hits']
        @parsed_response['hits'].map do |hit|
          Organization.new(hit)
        end
      else
        []
      end
    end

    def get_base_uri
      if GuidestarSearch.configuration.sandbox?
        GuidestarSearch::Configuration::SEARCH_SANDBOX_ENDPOINT
      else
        GuidestarSearch::Configuration::SEARCH_ENDPOINT
      end
    end

    def get_paging_options(search_options)
      page = nil
      per_page = nil

      if search_options[:page].present?
        page = search_options[:page].to_i
        search_options.delete(:page)
      end
      if search_options[:per_page].present?
        per_page = search_options[:per_page].to_i
        search_options.delete(:per_page)
      end

      [page,per_page,search_options]
    end

    def method_missing(name, *args, &block)
      if @parsed_response.has_key?(name.to_s)
        @parsed_response[name.to_s]
      else
        super
      end
    end
  end
end
