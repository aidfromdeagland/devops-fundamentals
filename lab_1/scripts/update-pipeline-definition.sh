#!/bin/bash

# @see: https://docs.aws.amazon.com/cli/latest/reference/codepipeline/update-pipeline.html


customPipelineJson="pipeline-$(date +'%Y_%m_%d_%H_%M').json"

# colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
#yel=$'\e[1;33m'
#blu=$'\e[1;34m'
#mag=$'\e[1;35m'
#cyn=$'\e[1;36m'
end=$'\e[0m'

checkJQ() {
  # jq test
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
}

# perform checks:
checkJQ

defaultPipeline="pipeline"
echo -n "Enter a CodePipeline name (default: $defaultPipeline): "
read -r pipelineName
pipelineName=${pipelineName:-$defaultPipeline}
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
defaultBranchName="main"
echo -n "Enter a source branch to use (default: $defaultBranchName): "
read -r branchName
branchName=${branchName:-$defaultBranchName}
jq --arg branch "$branchName" '.pipeline.stages[0].actions[0].configuration.Branch = $branch' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

defaultProceedOpt="y"
echo -n "Proceed with ${pipelineName} pipeline update? (y/n) (default: $defaultProceedOpt): "
read -r doProceed
doProceed=${doProceed:-$defaultProceedOpt}

if [ "$doProceed" = "n" ]; then
    echo "The ${pipelineName} pipeline update has been terminated."
    exit 0
fi

#upd owner
defaultGitHubOwner="aidfromdeagland"
echo -n "Enter a github owner name (default: $defaultGitHubOwner): "
read -r githubOwner
githubOwner=${githubOwner:-$defaultGitHubOwner}
jq --arg owner "$githubOwner" '.pipeline.stages[0].actions[0].configuration.Owner = $owner' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#upd repository
defaultRepository="shop-angular-cloudfront"
echo -n "Enter a repository name to use (default: $defaultRepository): "
read -r githubRepository
githubRepository=${githubRepository:-$defaultRepository}
jq --arg repo "$githubRepository" '.pipeline.stages[0].actions[0].configuration.Repo = $repo' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

#upd pollForChanges
defaultPollForChangesOpt="n"
shouldPollForChangesBoolean=false
echo -n "Should pipeline poll for changes? (y/n) (default: $defaultPollForChangesOpt): "
read -r shouldPollForChanges
shouldPollForChanges=${shouldPollForChanges:-$defaultPollForChangesOpt}

if [ "$shouldPollForChanges" = "y" ]; then
shouldPollForChangesBoolean=true
fi
jq --arg pollForSourceChanges "$shouldPollForChangesBoolean" '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges = $pollForSourceChanges' "$customPipelineJson" > tmp.$$.json && mv tmp.$$.json "$customPipelineJson"

printf "  ${grn}pipeline update successfuly finished\n${end}"
