# Copyright 2019 Pixar

#
#    Licensed under the Apache License, Version 2.0 (the "Apache License")
#    with the following modification; you may not use this file except in
#    compliance with the Apache License and the following modification to it:
#    Section 6. Trademarks. is deleted and replaced with:
#
#    6. Trademarks. This License does not grant permission to use the trade
#       names, trademarks, service marks, or product names of the Licensor
#       and its affiliates, except as required to comply with Section 4(c) of
#       the License and to reproduce the content of the NOTICE file.
#
#    You may obtain a copy of the Apache License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the Apache License with the above modification is
#    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied. See the Apache License for the specific
#    language governing permissions and limitations under the Apache License.
#
#

#
module JSS

  # Classes
  ###################################

  # The parent class of OSXConfigurationProfile and MobileDeviceConfigurationProfile
  #
  # Note that the profile payloads and the profile UUID cannot be edited or updated with this via this class.
  # Use the web UI.
  #
  # @see JSS::APIObject
  #
  class ConfigurationProfile < JSS::APIObject

    # Mix-Ins
    ###################################

    include JSS::Updatable
    include JSS::Scopable
    include JSS::SelfServable
    include JSS::Categorizable
    include JSS::Sitable

    # Class Constants
    ###################################

    # The possible values for the distribution_method/deployment_method
    DISTRIBUTION_METHODS = ['Install Automatically', 'Make Available in Self Service'].freeze

    # which DISTRIBUTION_METHODS means we're in self service?
    SELF_SERVICE_DIST_METHOD = 'Make Available in Self Service'.freeze

    # Our SelfService deploys profiles
    SELF_SERVICE_PAYLOAD = :profile

    # Where is the Site data in the API JSON?
    SITE_SUBSET = :general

    # Where is the Category in the API JSON?
    CATEGORY_SUBSET = :general

    # How is the category stored in the API data?
    CATEGORY_DATA_TYPE = Hash


    # Attributes
    ###################################

    # @return [String] the description of this profile
    attr_reader :description

    # @return [String] the uuid of this profile. NOT Updatable
    attr_reader :uuid

    # @return [Boolean] Should this profile be redeployed when an inventory update happens?
    attr_reader :redeploy_on_update

    # @return [String] the plist containing the payloads for this profile. NOT Updatable
    attr_reader :payloads

    # Constructor
    ###################################

    # See JSS::APIObject#initialize
    #
    def initialize(args = {})
      super
      @description = @main_subset[:description]
      @uuid = @main_subset[:uuid]
      @redeploy_on_update = @main_subset[:redeploy_on_update]
      @payloads = @main_subset[:payloads]
    end

    # Public Instance Methods
    ###################################

    # @param new_val[String] the new discription
    #
    # @return [void]
    #
    def description=(new_val)
      return nil if @self_service_description == new_val
      @description = new_val.strip!
      @need_to_update = true
    end # @param new_val[String] how should this be distributed to clients?

    # The @payloads Plist, parsed into a Ruby object
    #
    # @return [Hash] the parsed payloads plist.
    def parsed_payloads
      Plist.parse_xml @payloads
    end

    # @return [Array<Hash>] the individual payloads from the payload Plist
    #
    def payload_content
      parsed_payloads['PayloadContent']
    end

    # @return [Array<String>] the PayloadType of each payload (e.g. com.apple.caldav.account)
    #
    def payload_types
      payload_content.map { |p| p['PayloadType'] }
    end

    # Private Instance Methods
    ###################################
    private

    def rest_xml
      doc = REXML::Document.new

      obj = doc.add_element self.class::RSRC_OBJECT_KEY.to_s
      gen = obj.add_element('general')
      gen.add_element('description').text = @description
      gen.add_element('redeploy_on_update').text = @redeploy_on_update

      obj << @scope.scope_xml
      add_self_service_xml doc
      add_category_to_xml doc
      add_site_to_xml doc
      doc
    end

  end # class OSXConfigurationProfile

end # module

require 'jss/api_object/configuration_profile/osx_configuration_profile'
require 'jss/api_object/configuration_profile/mobile_device_configuration_profile'
