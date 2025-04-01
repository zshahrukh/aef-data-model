import sys
import argparse
import collections
import logging
import re
import json
from github import Auth
from github import Github


def extract_iam_metadata(file_content):
    """Extracts IAM metadata from file content and formats it as JSON.

    Args:
    file_content: The content of the .sqlx file.

    Returns:
    A JSON string containing the extracted IAM metadata, or None if no
    metadata is found.
    """
    # Find the iam_metadata block within the comments using regex
    match = re.search(r"//iam_metadata:\s*{(.*?)}", file_content, re.DOTALL)
    if match:
        metadata_block = match.group(1)
        # Remove comments and extra whitespace
        metadata_block = re.sub(r"//|\s", "", metadata_block)
        # Find the table name
        table_name_match = re.search(r"name:\s*\"([^\"]+)\"", file_content)
        table_name = table_name_match.group(1) if table_name_match else None

        # Construct the JSON output
        try:
            print(str(table_name))
            print(str(metadata_block))
            json_output = {
                "table": table_name,
                "iam_metadata": json.loads(metadata_block)
            }
            return json.dumps(json_output, indent=2)
        except json.JSONDecodeError as e:
            logging.error(f"Error decoding iam metadata JSON from .sqlx file: {e}")
            return None
    else:
        return None

def list_sqlx_files(repo):
    """Lists .sqlx files with 'ddl' tag in a GitHub repository.

    Args:
      repo: The GitHub repository object.
    """
    all_metadata = []
    contents = repo.get_contents("")
    while contents:
        file_content = contents.pop(0)
        if file_content.type == "dir":
            contents.extend(repo.get_contents(file_content.path))

        elif file_content.name.endswith(".sqlx"):
            file_path = file_content.path
            file_content = repo.get_contents(file_path).decoded_content.decode()
            if 'tags: ["ddl"]' in file_content:
                metadata = extract_iam_metadata(file_content)
                if metadata:
                    all_metadata.append(metadata)

    print(json.dumps(all_metadata, indent=2))


def main(args: collections.abc.Sequence[str]) -> int:
    """The main function parses command-line arguments and calls the run_workflow function to execute the complete Dataform workflow.
    To run the script, provide the required command-line arguments:
        python intro.py --project_id your_project_id --location your_location --repository your_repo_name --dataset your_bq_dataset --branch your_branch
    """
    parser = argparse.ArgumentParser(description="IAM metadata extractor from dataform repository")

    parser.add_argument("--remote_repo_url",
                        type=str,
                        required=True,
                        help="The github repository URL.")
    parser.add_argument("--dataform_repositories_git_token",
                        type=str,
                        required=True,
                        help="The GCP project Number where the Dataform code will be deployed.")

    params = parser.parse_args(args)
    remote_repo_url = str(params.remote_repo_url)
    dataform_repositories_git_token = str(params.dataform_repositories_git_token)

    auth = Auth.Token(dataform_repositories_git_token)
    g = Github(auth=auth)
    repo = g.get_user().get_repo("aef-sample-dataform-repo")

    list_sqlx_files(repo)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
