#!/usr/bin/env bash
# https://stackoverflow.com/questions/35045264/how-do-you-delete-an-aws-ecs-task-definition

REGION="us-east-1"

get_task_definition_arns() {
    aws ecs list-task-definitions --region $REGION \
        | jq -M -r '.taskDefinitionArns | .[]'
}

delete_task_definition() {
    local arn=$1

    aws ecs deregister-task-definition \
        --region $REGION \
        --task-definition "${arn}" > /dev/null
}

for arn in $(get_task_definition_arns)
do
    echo "Deregistering ${arn}..."
    delete_task_definition "${arn}"
done
