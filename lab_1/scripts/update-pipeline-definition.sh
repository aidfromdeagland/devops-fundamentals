#!/bin/bash

# @see: https://docs.aws.amazon.com/cli/latest/reference/codepipeline/update-pipeline.html

defaultPipeline="pipeline"
defaultBranchName="main"
defaultGitHubOwner="aidfromdeagland"
defaultRepository="shop-angular-cloudfront"
defaultPollForChangesBoolean=false
customPipelineJson="pipeline-$(date +'%Y_%m_%d_%H_%M').json"
isWizardFlow=false

# colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
end=$'\e[0m'

wizardFlow() {
echo -n "Enter a CodePipeline name (default: $defaultPipeline): "
read -r pipelineName
pipelineName=${pipelineName:-$defaultPipeline}

echo -n "Enter a source branch to use (default: $defaultBranchName): "
read -r branchName
branchName=${branchName:-$defaultBranchName}

echo -n "Enter a github owner name (default: $defaultGitHubOwner): "
read -r githubOwner
githubOwner=${githubOwner:-$defaultGitHubOwner}

echo -n "Enter a repository name to use (default: $defaultRepository): "
read -r githubRepository
githubRepository=${githubRepository:-$defaultRepository}

shouldPollForChangesBoolean=$defaultPollForChangesBoolean
echo -n "Should pipeline poll for changes? (y/n) (default: n): "
read -r shouldPollForChanges
shouldPollForChanges=${shouldPollForChanges:-"n"}

if [ "$shouldPollForChanges" = "y" ]; then
  shouldPollForChangesBoolean=true
fi
}

# check argument existence
if [ -z "$1" ]; then
  echo pipeline definition path is required, please provide path for pipeline definition or pass "--wizard" flag
  exit 1
fi

# jq check
type jq >/dev/null 2>&1
exitCode=$?

if [ "$exitCode" -ne 0 ]; then
  printf "  ${red}'jq' not found! (json parser)\n${end}"
  printf "    Ubuntu Installation: sudo apt install jq\n"
  printf "    Redhat Installation: sudo yum install jq\n"
  printf "    MacOs Installation: brew install jq\n"
  printf "    Windows Installation: curl -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe\n"
  exit 1
fi

# params parsing
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --wizard)
      isWizardFlow=true
      wizardFlow
      break
      ;;
    --branch)
      branchName="$2"
      shift 2
      ;;
    --owner)
      githubOwner="$2"
      shift 2
      ;;
    --poll-for-source-changes)
      shouldPollForChangesBoolean="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ $isWizardFlow = true ]]; then
  pipelineJson="$pipelineName.json"
else
  pipelineJson="$1"
fi

pipelineJson="$pipelineName.json"
if [[ ! -f "$pipelineJson" ]]; then
  echo there is no JSON with "$pipelineName" name
  exit 1
fi

# remove metadata
jq 'del(.metadata)' "$pipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

# increase version
jq '.pipeline.version += 1' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

# upd source branch
jq --arg branch "$branchName" '.pipeline.stages[0].actions[0].configuration.Branch = $branch' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#upd owner
jq --arg owner "$githubOwner" '.pipeline.stages[0].actions[0].configuration.Owner = $owner' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#upd repository
jq --arg repo "$githubRepository" '.pipeline.stages[0].actions[0].configuration.Repo = $repo' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#upd pollForChanges
jq --arg pollForSourceChanges "$shouldPollForChangesBoolean" '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges = $pollForSourceChanges' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#show updated pipeline
cat "$customPipelineJson" | jq

printf "  ${grn}pipeline update successfuly finished\n${end}"
