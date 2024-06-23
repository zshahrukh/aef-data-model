# Copyright 2024 Google LLC
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

import logging
import subprocess
import os
import shutil
import json
import sys
import argparse
import collections

def run_deploy_data_mesh(config_file, tag_template_directories, policy_directories, lake_directories,
                         annotation_directories, overwrite):
    """Runs the 'deploy_data_mesh.py' script with provided arguments.

    Args:
        config_file (str): Path to the configuration JSON file.
        tag_template_directories (str): Path to the tag template directories.
        policy_directories (str): Path to the policy taxonomies directories.
        lake_directories (str): Path to the lake directories.
        annotation_directories (str): Path to the annotation directories.
        overwrite (bool): Whether to overwrite existing data.
    """
    src_code_path = "metadata/metadata-deployer/cortex_src_code"
    if os.path.exists(src_code_path):
        shutil.rmtree(src_code_path)
        subprocess.run(["git", "rm", "-rf", "--cached", src_code_path], check=True)

    subprocess.run(["git", "submodule", "add", "-f", "https://github.com/GoogleCloudPlatform/cortex-data-foundation.git",
                    src_code_path])
    command = [
        "python3",
        "metadata/metadata-deployer/cortex_src_code/src/common/data_mesh/deploy_data_mesh.py",
        "--config-file", config_file,
        "--tag-template-directories", tag_template_directories,
        "--policy-directories", policy_directories,
        "--lake-directories", lake_directories,
        "--annotation-directories", annotation_directories
    ]
    if overwrite != "false":
        command.append("--overwrite")

    requirements_path = "metadata/metadata-deployer/cortex_src_code/requirements.in"

    # Check if dependencies are installed
    if not all([os.path.exists(req) for req in open(requirements_path)]):
        new_lines = [
            "exceptiongroup",
            "google-api-core",
            "google-cloud-bigquery",
            "google-cloud-bigquery-datapolicies",
            "google-cloud-datacatalog",
            "google-cloud-dataplex",
        ]
        add_lines_to_file(requirements_path, new_lines)
        subprocess.run([f"pip", "install", "-r", requirements_path], check=True)

    subprocess.run(command, check=True)


def write_json_file(project_id, location, output_filename="cortex_config.json"):
    """Creates a JSON file with the specified project ID and location.
    Args:
        project_id (str): The project ID to include in the JSON.
        location (str):  The location to include in the JSON.
        output_filename (str, optional): The filename of the output JSON file. Defaults to "config.json".
    """
    data = {
        "deployDataMesh": True,
        "projectIdSource": project_id,
        "projectIdTarget": project_id,
        "targetBucket": f"{project_id}-cortex-tmp-bucket",
        "location": location,
        "DataMesh": {
            "deployDescriptions": True,
            "deployLakes": True,
            "deployCatalog": True,
            "deployACLs": True
        },
        "k9": {
            "datasets": {
                "processing": "K9_PROCESSING",
                "reporting": "K9_REPORTING"
            }
        }
    }
    with open(output_filename, "w") as outfile:
        json.dump(data, outfile, indent=4)
    return output_filename


def add_lines_to_file(filename, new_lines):
    """Appends new lines to the end of a file, handling potential errors.
    Args:
        filename (str): The path to the flat file.
        new_lines (list): A list of strings representing the new lines to add.
    """
    try:
        with open(filename, 'a') as file:  # 'a' for append mode
            for line in new_lines:
                file.write(line + '\n')  # Add a newline character
        print("Lines added successfully!")

    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
    except IOError:
        print(f"Error: An I/O error occurred while working with '{filename}'.")


def main(args: collections.abc.Sequence[str]) -> int:
    parser = argparse.ArgumentParser(description="Cortex Data Mesh Deployer")
    parser.add_argument("--project_id",
                        type=str,
                        required=True,
                        help="Project where metadata (lakes, zones, tags, etc.) will be deployed.")
    parser.add_argument("--location",
                        type=str,
                        required=True,
                        help="Location where metadata (lakes, zones, tags, etc.) will be deployed.")
    parser.add_argument("--overwrite",
                        type=str,
                        required=True,
                        help="Whether to overwrite existing metadata")
    params = parser.parse_args(args)
    project_id = str(params.project_id)
    location = str(params.location)
    overwrite = str(params.overwrite)

    run_deploy_data_mesh(
        config_file=write_json_file(project_id, location),
        tag_template_directories="../metadata/tag_templates",
        policy_directories="../metadata/policy_taxonomies",
        lake_directories="../metadata/lakes",
        annotation_directories="../metadata/annotations",
        overwrite=overwrite
    )

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))