# Copyright 2025 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@rosidl_adapter//:aspects.bzl", "rosidl_adapter_aspect")
load("@rosidl_adapter//:tools.bzl", "unmangle_library_name")
load("@rosidl_adapter_proto//:aspects.bzl", "rosidl_adapter_proto_aspect")
load("@rosidl_cmake//:types.bzl", "RosInterfaceInfo")
load("@rosidl_generator_c//:aspects.bzl", "rosidl_generator_c_aspect")
load("@rosidl_generator_c//:types.bzl", "RosCBindingsInfo")
load("@rosidl_generator_type_description//:aspects.bzl", "rosidl_generator_type_description_aspect")
load("@rosidl_typesupport_introspection_cpp//:aspects.bzl", "rosidl_typesupport_introspection_cpp_aspect")
load("@rosidl_typesupport_introspection_cpp//:types.bzl", "RosCcTypesupportIntrospectionInfo")
load("@rosidl_typesupport_fastrtps_cpp//:aspects.bzl", "rosidl_typesupport_fastrtps_cpp_aspect")
load("@rosidl_typesupport_fastrtps_cpp//:types.bzl", "RosCcTypesupportFastRTPSInfo")
load("@rosidl_typesupport_protobuf_cpp//:aspects.bzl", "rosidl_typesupport_protobuf_cpp_aspect")
load("@rosidl_typesupport_protobuf_cpp//:types.bzl", "RosCcTypesupportProtobufInfo")
load("@rosidl_typesupport_cpp//:aspects.bzl", "rosidl_typesupport_cpp_aspect")
load("@rosidl_typesupport_cpp//:types.bzl", "RosCcTypesupportInfo")
load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load(":aspects.bzl", "rosidl_generator_cpp_aspect")
load(":types.bzl", "RosCcBindingsInfo")

# We need to make sure the final libraries from these providers end up
# in the runfiles, so that they can be loaded dynamically via dlopen()
TYPESUPPORT_PROVIDERS = [
    RosCBindingsInfo,
    RosCcBindingsInfo,
    RosCcTypesupportIntrospectionInfo,
    RosCcTypesupportFastRTPSInfo,
    RosCcTypesupportProtobufInfo,
    RosCcTypesupportInfo,
]

def _cc_ros_library(ctx):

    # Move all the dynamic libraries into one search location.
    symlinks = {}
    direct_cc_infos = []
    for dep in ctx.attr.deps:
        for provider in TYPESUPPORT_PROVIDERS:
            if provider in dep:
                direct_cc_infos.append(dep[provider].cc_info)
                for file in dep[provider].dynamic_libraries.to_list():
                    unmangled_name = unmangle_library_name(file.basename)
                    symlinks["lib/" + unmangled_name] = file

    # Package up the runfiles
    default_info = DefaultInfo(
        runfiles = ctx.runfiles(
            files = symlinks.values(),
            symlinks = symlinks,
        )
    )
    
    # Package up the CcInfo
    cc_info = cc_common.merge_cc_infos(direct_cc_infos = direct_cc_infos)

    return [default_info, cc_info]

cc_ros_library = rule(
    implementation = _cc_ros_library,
    attrs = {
        "deps": attr.label_list(
            aspects = [
                # Adapters
                rosidl_adapter_aspect,
                rosidl_generator_type_description_aspect,
                rosidl_adapter_proto_aspect,
                # Generators
                rosidl_generator_c_aspect,
                rosidl_generator_cpp_aspect,
                # C++ typesupports
                rosidl_typesupport_introspection_cpp_aspect,
                rosidl_typesupport_fastrtps_cpp_aspect,
                rosidl_typesupport_protobuf_cpp_aspect,
                rosidl_typesupport_cpp_aspect,
            ],
            providers = [RosInterfaceInfo],
            allow_files = False,
        ),
    },
    provides = [CcInfo],
)
