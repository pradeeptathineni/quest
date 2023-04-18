# Quest Service Project Documentation

The quest service is a good representation of DevOps in action. It uses technologies such as Docker, Terraform, AWS, CircleCI, and Make to support AWS deployments of our Node.js web application and its architecture. This architecture is necessary to loadbalance HTTP and HTTPS traffic over multiple AWS availability zones to serverless ECS containers hosting our Node.js web application.

## Project Prerequisites

-   A Github account.
    -   Visit [Github](https://github.com/signup) to sign up.
-   Git installed locally on your machine.
    -   Visit [Installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for instructions.
-   Git configured locally with your Github user information.
    -   Visit [Git Configuration](https://www.git-scm.com/book/en/v2/Customizing-Git-Git-Configuration) for instructions.
-   An AWS account.
    -   Visit [AWS Registration](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) to sign up.
-   Access to an admin AWS user with programmatic access, and its AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
    -   Visit [Creating Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) for instructions on creating users in the AWS console, or please contact your company's AWS cloud administrator for assistance in creating this in a development or test AWS account.

## Deploy Guidelines

### CircleCI Deploy (CICD)

#### Getting Started

1. Open a command terminal on your machine.
2. Clone this repo: `git clone https://github.com/pradeeptathineni/quest`
3. Commit changes to your local repo copy where you update variables in both /terraform/variables.tf files under /.service and /.cicd:
    - service (must be the same name as this repo)
    - profile (default has been tested but feel free to try another)
    - region (your preferred AWS region to deploy in)
4. Create a [CircleCI account](https://circleci.com/), or authenticate using Github.
5. Go to the [CircleCI application](https://app.circleci.com/dashboard).
6. In the top left of CircleCI, choose the Github organization that holds this repo.
7. "Follow" this project in CircleCI, choose the master branch and default config.yml location, and go to the project.
8. In the top right of CircleCI, configure project settings for this repo, and add the following environment variables with the values you choose:
    - AWS_REGION (must follow the region variable you set in \*/terraform/variables.tf)
    - AWS_ACCESS_KEY_ID (aws creds must have admin access)
    - AWS_SECRET_ACCESS_KEY (aws creds must have admin access)

#### CircleCI Deploy Steps

When you want to deploy:

1. Go back to your repo locally where you cloned it.
2. Commit a change where you uncomment the workflow named "deploy" in the .circleci/config.yml.
3. This will cause the CircleCI project project to trigger a pipeline for the deploy job.
    - Congratulations, you just began the first CircleCI pipeline!
    - Any subsequent changes pushed to the master branch (commits, pull requests, etc) will trigger this pipeline.

When you want to destroy the architecture:

1.  Go back to your repo locally where you cloned it.
2.  Commit a change where you comment the workflow named "deploy" and uncomment the workflow named "destroy" in the .circleci/config.yml.
3.  This will cause the CircleCI project to trigger a pipeline for the destroy job.

### Local Deploy (Manual)

#### Getting Started

1. Have the necessary software installed on your local machine:
    - Docker. Visit [Install Docker Engine](https://docs.docker.com/engine/install/) for instructions.
    - Terraform CLI. Visit [Install Terraform for AWS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for instructions.
    - AWS CLI. Visit [Installing AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for instructions.
2. Open a command terminal on your machine.
3. Clone this repo: `git clone https://github.com/pradeeptathineni/quest`
4. Commit a change to your local repo copy where you update the Makefile's variables:
    - SERVICE (must be the same name as this repo)
    - AWS_ACCOUNT_ID (your AWS account ID)
    - REGION (your preferred AWS region to deploy in)
5. Go back to the command terminal and configure your AWS CLI default profile: `aws configure`

#### Local Deploy Steps

When you want to deploy the architecture:

-   Run make in the local repo copy root: `make local-deploy`

When you want to destroy the architecture:

-   Run make in the local repo copy root: `make destroy`

##### \*\*\* PLEASE NOTE: If you delete the Terraform state bucket in AWS S3 before you wipe the Terraform service architecture, you may be in a pickle that requires you to manually delete all those AWS resources. To avoid this, follow the automated steps defined here. \*\*\*

## Usage

Once the infrastructure is deployed, you can access the weba application by navigating to the public DNS address of the loadbalancer in your web browser. You can find the public IP address in the Terraform output or in the AWS EC2 console.

Every time a change is pushed to the master branch, such as a commit or pull request, the CircleCI pipeline will kick off the workflow defined in the .circleci/config.yml file. Remember to update and commit the workflows as needed.

The Makefile provides helpful commands to control the architecture deployment from your local machine. Since the state of our Terraform service project is saved in AWS S3, changes to the Terraform architecture can occur from anywhere, as long as you initialize the Terraform project with the backend so the Terraform state file is considered.

When you are finished testing, it's a good idea to tear down the infrastructure. Please do so using the CircleCI workflow named "destroy or Makefile rule named "destroy".

## Conclusion

That's it! You now have a fully functional web application architecture deployed on AWS using Terraform. If you have any questions or run into any issues, feel free to open an issue on this repository. Thank you for testing out this quest service implementation!
