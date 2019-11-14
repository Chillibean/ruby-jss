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

module JamfRubyExtensions

  module Array

    module Utils

        # Fetch a string from an Array of Strings case-insensitively,
        # e.g. my_array.j_ci_fetch_string('ThRashEer') will return 'thrasher'
        # or nil if no match
        #
        # @param somestring [String] the String to search for
        #
        # @return [String, nil] The matching string as it exists in the Array, nil if it doesn't exist
        #
        def j_ci_fetch_string(somestring)
          idx = index { |s| s.to_s.casecmp? somestring }
          idx ? self[idx] : nil
        end

    end # module

  end # module

end # module