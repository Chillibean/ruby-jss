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

  # Sub-Modules
  ###################################

  # A mix-in module for handling extension attribute data for objects in the JSS.
  #
  # This module provides standardized ways to deal with Extension Attribute data
  # in objects that gather that data  ({JSS::Computer}s, {JSS::MobileDevice}s,
  # and {JSS::User}s). For working with the Extension Attributes themselves, see
  # {JSS::ExtensionAttribute} and its subclasses.
  #
  # API objects that have Extension Attribute data return it in an Array of Hashes,
  # one for each defined ExtensionAttribute for the class;
  # i.e. a {JSS::Computer}'s Array has one Hash for each {JSS::ComputerExtensionAttribute}
  # defined in the JSS.
  #
  # The Hash keys are:
  # * :id => the ExtAttr id
  # * :name => the ExtAttr name
  # * :type => the data type of the ExtAttr value
  # * :value => the value for the ExtAttr for this object as of the last report.
  #
  # Classes including this module must define the constant EXT_ATTRIB_CLASS
  # specifying which {JSS::ExtensionAttribute} subclass defines the relevant extension attributes.
  # For Example, {JSS::Computer} sets this:
  #   EXT_ATTRIB_CLASS = JSS::ComputerExtensionAttribute
  #
  #
  # Parsing also populates @ext_attrs which is a Hash of name => value for each EA.
  #
  # When updating or creating, those classes must add the REXML output of {#ext_attr_xml} to their
  # rest_xml output.
  #
  module Extendable

    #  Constants
    ###################################

    EXTENDABLE = true

    # ExtensionAttributes refer to the numeric data type as "Integer"
    # but the ext. attr values that come with extendable objects refer to
    # that data type as "Number".  Here's an array with both, so we can
    # work with ether more easily.
    NUMERIC_TYPES = %w[Number Integer].freeze

    #  Attribtues
    ###################################

    # @return [Array<Hash>] The extension attribute values for the object
    attr_reader :extension_attributes

    # @return [Hash] A mapping of Ext Attrib names to their values
    attr_reader :ext_attrs

    #  Mixed-in Instance Methods
    ###################################

    # Populate @extension_attributes (the Array of Hashes that comes from the API)
    # and @ext_attr_names, which is a Hash mapping the EA names to their
    # values. This is called during initialization for all objects
    # that mix in this module
    #
    # @return [void]
    #
    def parse_ext_attrs
      @extension_attributes = @init_data[:extension_attributes]
      @extension_attributes ||= []
      @ext_attrs = {}

      @extension_attributes.each do |ea|
        case ea[:type]

        when 'Date'
          begin # if there's random non-date data, the parse will fail
            ea[:value] = JSS.parse_datetime ea[:value]
          rescue
            true
          end

        when *NUMERIC_TYPES
          ea[:value] = ea[:value].to_i unless ea[:value].to_s.empty?
        end # case

        @ext_attrs[ea[:name]] = ea[:value]
      end # each do ea

      # remember changes as they happen so
      # we only send changes back to the server.
      @changed_eas = []
    end

    # Set the value of an extension attribute
    #
    # If the extension attribute is defined as a popup menu, the value must be one of the
    # defined popup choices, or an empty string
    #
    # If the ext. attrib. is defined with a data type of Integer, the value must be an Integer.
    #
    # If the ext. attrib. is defined with a data type of Date, the value will be converted to a Time
    #
    # Note that while the Jamf Pro Web interface does not allow editing the values of
    # Extension Attributes populated by Scripts or LDAP,  the API does allow it.
    # Bear in mind however that those values will be reset again at the next recon.
    #
    # @param name[String] the name of the extension attribute to set
    #
    # @param value[String,Time,Time,Integer] the new value for the extension attribute for this user
    #
    # @return [void]
    #
    def set_ext_attr(name, value)
      # this will raise an exception if the name doesn't exist
      ea_def = self.class::EXT_ATTRIB_CLASS.fetch name: name, api: api

      if ea_def.input_type == 'Pop-up Menu' && (!ea_def.popup_choices.include? value.to_s)
        raise JSS::UnsupportedError, "The value for #{name} must be one of: '#{ea_def.popup_choices.join("' '")}'"
      end

      unless value == JSS::BLANK
        case ea_def.data_type
        when 'Date'
          value = JSS.parse_datetime value

        when *NUMERIC_TYPES
          raise JSS::InvalidDataError, "The value for #{name} must be an integer" unless value.is_a? Integer

        end # case
      end # unless blank

      been_set = false
      @extension_attributes.each do |ea|
        next unless ea[:name] == name
        ea[:value] = value
        been_set = true
      end
      unless been_set
        @extension_attributes << { id: ea_def.id, name: name, type: ea_def.data_type, value: value }
      end

      @ext_attrs[name] = value
      @changed_eas << name
      @need_to_update = true
    end

    # are there any changes in the EAs needing to be saved?
    #
    # @return [Boolean]
    #
    def unsaved_eas?
      @need_to_update && @changed_eas && !@changed_eas.empty?
    end

    # @api private
    #
    # TODO: make this (and all XML amending) method take the in-progress XML doc and
    # add (or not) the EA xml to it.
    # See how Sitable#add_site_to_xml works, as called from
    # Computer.rest_xml
    #
    # @return [REXML::Element] An <extension_attribute> element to be
    #  included in the rest_xml of objects that mix-in this module.
    #
    def ext_attr_xml
      @changed_eas ||= []
      eaxml = REXML::Element.new('extension_attributes')
      @extension_attributes.each do |ea|
        next unless @changed_eas.include? ea[:name]
        ea_el = eaxml.add_element('extension_attribute')
        ea_el.add_element('name').text = ea[:name]

        if ea[:type] == 'Date'
          begin
            ea_el.add_element('value').text = ea[:value].to_jss_date
          rescue
            ea_el.add_element('value').text = ea[:value].to_s
          end
        else
          ea_el.add_element('value').text = ea[:value].to_s
        end # if
      end # each do ea

      eaxml
    end

  end # module Purchasable

end # module JSS
