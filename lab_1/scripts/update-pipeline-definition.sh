#!/bin/bash

# @see: https://docs.aws.amazon.com/cli/latest/reference/codepipeline/update-pipeline.html

defaultPipeline="pipeline"
defaultBranchName="main"
defaultGitHubOwner="aidfromdeagland"
defaultRepository="shop-angular-cloudfront"
defaultConfiguration="production"
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
else 
  firstArgument="$1"
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
      --configuration)
      buildConfiguration="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ $isWizardFlow = true ]; then
  pipelineJson="$pipelineName.json"
else
  pipelineJson="$firstArgument"
fi

if [[ ! -f "$pipelineJson" ]]; then
  echo there is no JSON with "$pipelineName" name
  exit 1
fi

# remove metadata
jq 'del(.metadata)' "$pipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

# increase version
jq '.pipeline.version += 1' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

sourceStageIndex="$(jq '.pipeline.stages | map(.name == "Source") | index(true)' "$customPipelineJson")"
sourceStageContent="$(jq --arg stageIndex "$sourceStageIndex" '.pipeline.stages[$stageIndex | tonumber]' "$customPipelineJson")"
sourceActionIndex="$(echo "$sourceStageContent" | jq  '.actions | map(.name == "Source") | index(true)')"

# upd source branch
if [ "$branchName" ]; then
  jq --arg branch "$branchName" --arg stageIndex "$sourceStageIndex" --arg actionIndex "$sourceActionIndex" \
  '.pipeline.stages[$stageIndex | tonumber].actions[$actionIndex | tonumber].configuration.Branch = $branch' \
  "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"
fi

#upd owner
if [ "$githubOwner" ]; then
  jq --arg owner "$githubOwner" --arg stageIndex "$sourceStageIndex" --arg actionIndex "$sourceActionIndex" \
  '.pipeline.stages[$stageIndex | tonumber].actions[$actionIndex | tonumber].configuration.Owner = $owner' \
  "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"
fi

#upd repository
if [ "$githubRepository" ]; then
  jq --arg repo "$githubRepository" --arg stageIndex "$sourceStageIndex" --arg actionIndex "$sourceActionIndex" \
  '.pipeline.stages[$stageIndex | tonumber].actions[$actionIndex | tonumber].configuration.Repo = $repo' \
  "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"
fi

#upd pollForChanges
if [ "$shouldPollForChangesBoolean" ]; then
  jq --arg pollForSourceChanges "$shouldPollForChangesBoolean"  --arg stageIndex "$sourceStageIndex" --arg actionIndex "$sourceActionIndex" \
  '.pipeline.stages[$stageIndex | tonumber].actions[$actionIndex | tonumber].configuration.PollForSourceChanges = $pollForSourceChanges' \
  "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"
fi

#upd environment variables
if [ "$buildConfiguration" ]; then
  jq --arg configuration "$buildConfiguration" \
  '.pipeline.stages[].actions[].configuration |= if (has("EnvironmentVariables")) then (.EnvironmentVariables |= gsub("{{BUILD_CONFIGURATION value}}"; $configuration)) else . end' \
  "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"
fi

#show updated pipeline
cat "$customPipelineJson" | jq

printf "  ${grn}pipeline update successfuly finished\n${end}"
