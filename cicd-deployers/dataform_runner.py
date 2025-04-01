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
import time
import argparse
import collections
import sys
import json
import re
from google.cloud import dataform_v1beta1
from google.cloud import asset_v1
df_client = dataform_v1beta1.DataformClient()
iam_client = asset_v1.AssetServiceClient()


def execute_workflow(repo_uri: str, compilation_result: str, tags: list):
    """Triggers a Dataform workflow execution based on a provided compilation result.

    Args:
        repo_uri (str): The URI of the Dataform repository.
        compilation_result (str): The name of the compilation result to use.

    Returns:
        str: The name of the created workflow invocation.
    """
    invocation_config = dataform_v1beta1.types.InvocationConfig(
        included_tags=tags
    )
    request = dataform_v1beta1.CreateWorkflowInvocationRequest(
        parent=repo_uri,
        workflow_invocation=dataform_v1beta1.types.WorkflowInvocation(
            compilation_result=compilation_result,
            invocation_config=invocation_config
        )
    )
    response = df_client.create_workflow_invocation(request=request)
    name = response.name
    logging.info(f'created workflow invocation {name}')
    return name


def compile_workflow(repo_uri: str, branch: str):
    """Compiles a Dataform workflow using a specified Git branch.

    Args:
        repo_uri (str): The URI of the Dataform repository.
        gcp_project (str): The GCP project ID.
        tag (str): The dataform tag to compile.
        branch (str): The Git branch to compile.

    Returns:
        str: The name of the created compilation result.
    """
    request = dataform_v1beta1.CreateCompilationResultRequest(
        parent=repo_uri,
        compilation_result=dataform_v1beta1.types.CompilationResult(
            git_commitish=branch
        )
    )
    response = df_client.create_compilation_result(request=request)
    name = response.name
    logging.info(f'compiled workflow {name}')
    return name


def get_workflow_status(workflow_invocation_name):
    """Monitors the status of a Dataform workflow invocation.

    Args:
        workflow_invocation_name (str): The ID of the workflow invocation.
        df_client: The Dataform client object.
    """
    while True:
        request = dataform_v1beta1.GetWorkflowInvocationRequest(
            name=workflow_invocation_name
        )
        response = df_client.get_workflow_invocation(request)
        state = response.state.name
        logging.info(f'workflow state: {state} for {workflow_invocation_name}')

        if state == 'RUNNING':
            time.sleep(4)
            continue
        if state in ('FAILED', 'CANCELING', 'CANCELLED'):
            raise Exception(f'Error while running workflow {workflow_invocation_name}')
        elif state == 'SUCCEEDED':
            return
        break
    return


def run_workflow(gcp_project: str, project_num: str, location: str, repo_name: str, tags: list, execute: str,
                 branch: str):
    """Orchestrates the complete Dataform workflow process: compilation and execution.

    Args:
        gcp_project (str): The GCP project ID.
        project_num (str): The GCP project Number.
        location (str): The GCP region.
        repo_name (str): The name of the Dataform repository.
        tag (str): The target tags to compile and execute.
        branch (str): The Git branch to use.
    """
    repo_uri = f'projects/{gcp_project}/locations/{location}/repositories/{repo_name}'
    compilation_result = compile_workflow(repo_uri, branch)

    if execute:
        workflow_invocation_name = execute_workflow(repo_uri, compilation_result, tags)
        get_workflow_status(workflow_invocation_name)

    print(json.dumps({}, indent=2))

def extract_config_name(file_path):
  """
  Extracts the config name from a Dataform SQLX file.

  Args:
    file_path: Path to the SQLX file.

  Returns:
    The config name as a string, or None if not found.
  """
  try:
    with open(file_path, 'r') as f:
      content = f.read()

    match = re.search(r'config \{.*?name: "(.*?)"', content, re.DOTALL)
    if match:
      return match.group(1)
    else:
      logging.info(f"Config name not found in {file_path}.")
      return None
  except FileNotFoundError:
    logging.info(f"File not found: {file_path}")
    return None

def extract_iam_metadata(file_path):
  """
  Extracts IAM metadata from a Dataform SQLX file.

  Args:
    file_path: Path to the SQLX file.

  Returns:
    A dictionary containing the IAM metadata, or None if not found.
  """
  with open(file_path, 'r') as f:
    content = f.read()

  match = re.search(r'//iam_metadata: ({[\s\S]*?})', content)
  if match:
    json_str = match.group(1).replace("//", "")
    try:
      iam_metadata = json.loads(json_str)
      return iam_metadata
    except json.JSONDecodeError:
      logging.info("Error decoding JSON metadata.")
      return None
  else:
    logging.info("IAM metadata not found in the file.")
    return None


def validate_service_account(project_id, service_account_email, required_role):
    """
    Validates if a Google Cloud service account exists and has a specified role.

    Args:
        project_id: The ID of the Google Cloud project.
        service_account_email: The email address of the service account.
        required_role: The role the service account should have (e.g., "roles/storage.objectAdmin").

    Returns:
        True if the service account exists and has the role, False otherwise.
    """

    # Construct the service account resource name
    resource_name = f"//iam.googleapis.com/projects/{project_id}/serviceAccounts/{service_account_email}"

    # Analyze IAM policy for the service account
    response = iam_client.analyze_iam_policy(
        request={
            "analysis_query": {
                "scope": f"projects/{project_id}",
                "resource_selector": {"full_resource_name": resource_name},
                "identity_selector": {"identity": f"serviceAccount:{service_account_email}"}
            }
        }
    )

    # Check if the required role is in the policy bindings
    for binding in response.main_analysis.analysis_results[0].iam_binding.bindings:
        if required_role in binding.role:
            return True

    return False

    logging.info(f"Service account {service_account_email} does not have the role {required_role} in project {project_id}.")
    return False

def main(args: collections.abc.Sequence[str]) -> int:
    """The main function parses command-line arguments and calls the run_workflow function to execute the complete Dataform workflow.
    To run the script, provide the required command-line arguments:
        python intro.py --project_id your_project_id --location your_location --repository your_repo_name --dataset your_bq_dataset --branch your_branch
    """
    parser = argparse.ArgumentParser(description="Dataform Workflows runner")

    parser.add_argument("--project_id",
                        type=str,
                        required=True,
                        help="The GCP project ID where the Dataform code will be deployed.")
    parser.add_argument("--project_number",
                        type=str,
                        required=True,
                        help="The GCP project Number where the Dataform code will be deployed.")
    parser.add_argument("--location",
                        type=str,
                        required=True,
                        help="The location of the Dataform repository.")
    parser.add_argument("--repository",
                        type=str,
                        required=True,
                        help="The name of the Dataform repository to compile and run")
    parser.add_argument("--tags",
                        nargs="*",  # 0 or more values expected => creates a list
                        type=str,
                        required=True,
                        help="The target tags to compile and execute")
    parser.add_argument("--execute",
                        type=str,
                        required=True,
                        help="Control if dataform repository will be executed or compiled only.")
    parser.add_argument("--branch",
                        type=str,
                        required=True,
                        help="The branch of the Dataform repository to use.")
    params = parser.parse_args(args)
    project_id = str(params.project_id)
    project_number = str(params.project_number)
    location = str(params.location)
    repository = str(params.repository)
    execute = str(params.execute)
    tags = list(params.tags)
    branch = str(params.branch)

    run_workflow(gcp_project=project_id,
                 project_num=project_number,
                 location=location,
                 repo_name=repository,
                 tags=tags,
                 execute=execute,
                 branch=branch)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
