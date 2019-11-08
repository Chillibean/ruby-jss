# Copyright 2018 Pixar
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

module Jamf

  # This mixin overrides JSONObject.mutable? to return false,
  # meaning that no setters are ever defined for classes that include this.
  #
  module Immutable

    # By default, JSONObjects (as a whole) are mutable,
    # although some attributes may not be (see OBJECT_MODEL in the JSONObject
    # docs)
    #
    # When an entire sublcass of JSONObject is read-only/immutable,
    # extend Jamf::Immutable, which will override this to return false
    #
    def mutable?
      false
    end

  end # Lockable

end # Jamf