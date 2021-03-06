# Copyright (c) 2016 Code42, Inc.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
module Code42
  module API
    module Org
      ### Orgs :post, :get, :put, :delete ###

      # Creates blue org as well as user for the org
      # @return [Code42::Org] The created org
      # @param attrs [Hash] A hash of attributes to assign to created org
      # @example
      #   client.create_org(:company => "test", :email => "test@test.com", :firstname => "test", :lastname => "test")
      def create_pro_org(attrs = {})
        object_from_response(Code42::Org, :post, "proOrgChannel", attrs)
      end

      # Creates an org
      # @return [Code42::Org] The created org
      # @param attrs [Hash] A hash of attributes to assign to created org
      # @example
      #   client.create_org(:name => 'Acme Org', :parent_id => 2)
      def create_org(attrs = {})
        object_from_response(Code42::Org, :post, "org", attrs)
      end

      # Returns information for a given org
      # @return [Code42::Org] The requested org
      # @param id [String, Integer] A code42 user ID
      def org(id = "my", params = {})
        object_from_response(Code42::Org, :get, "org/#{id}", params)
      end

      # Returns an org for a given name.  If multiple orgs are found, the first found will
      # be returned.
      # @return [Code42::Org] The requested org
      # @param name [String] A Code42 org name
      # @param params [Hash] Additional params used by the server for filtering, output, etc.
      # FIXME: This needs to change when the API implements a better way.
      def find_org_by_name(name, params = {})
        search_orgs(name, params).select { |o| o.name == name }.first
      end

      # Returns the first org that starts with a given name.
      # Since orgs are renamed when they are deactivated, it is impossible
      # to guarantee a match by name alone.
      # @param name [String] A Code42 org name
      # @param params [Hash] Additional params used by the server for filtering, output, etc.
      def find_inactive_org_by_name(name, params = {})
        search_orgs(name, params.merge!(:active => false)).first
      end

      # Searches orgs for a query string
      # @return [Array] An array of matching orgs
      # @param query [String] A string to search for
      def search_orgs(query, params = {})
        params.merge!(q: query)
        orgs(params)
      end

      # Returns a list of up to 100 orgs
      # @return [Array] An array of matching orgs
      # @param params [Hash] A hash of parameters to match results against
      def orgs(params = {})
        params.merge!(key: 'orgs')
        objects_from_response(Code42::Org, :get, 'org', params)
      end

      def update_org(id = 'my', attrs = {})
        object_from_response(Code42::Org, :put, "org/#{id}", attrs)
      end

      def activate_org(id = 'my', attrs = {})
        object_from_response(Code42::Org, :delete, "OrgDeactivation/#{id}", attrs)
      end

      def deactivate_org(id = 'my', attrs = {})
        object_from_response(Code42::Org, :put, "OrgDeactivation/#{id}", attrs)
      end

      def block_org(id = 'my', attrs = {})
        object_from_response(Code42::Org, :put, "orgBlock/#{id}", attrs)
      end

      def unblock_org(id = 'my', attrs = {})
        object_from_response(Code42::Org, :delete, "orgBlock/#{id}", attrs)
      end

      def org_share_destinations(id)
        get("orgShareDestinations/#{id}")['data']
      end

    end
  end
end
