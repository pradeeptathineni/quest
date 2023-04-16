# Quest Discussion

## Steps to Deploy

### CircleCI Deploy (Fun)

-   After having git, docker, terraform, and the AWS CLI installed, run the following commands to deploy the app:
-   Clone this repo: `git clone https://github.com/pradeeptathineni/quest`
    -   Commit changes where you update variables in \*/terraform/variables.tf:
        1. service (must be the same name as this repo)
        2. profile (default has been tested but feel free to try another)
        3. region (your preferred AWS region to deploy in)
-   Create a [CircleCI account](https://circleci.com/), or authenticate using Github.
-   Go to the [CircleCI application](https://app.circleci.com/dashboard).
    -   Connect it to your Github organization that holds this repo.
    -   Add this repo as a project; follow this project in CircleCI.
    -   Configure project settings for this repo in the top right corner, and add the following environment variables with the values you choose:
        1. AWS_REGION (must follow the region variable you set in \*/terraform/variables.tf)
        2. AWS_ACCESS_KEY_ID (aws creds must have admin access)
        3. AWS_SECRET_ACCESS_KEY (aws creds must have admin access)
-   When you want to deploy:
    -   Go back to your repo locally where you cloned it.
    -   Commit a change where you uncomment the workflow named "deploy" in the .circleci/config.yml.
    -   This will cause the CircleCI project project to trigger a pipeline for the destroy job.
    -   Congratulations, you just began the first CircleCI pipeline!
    -   Any subsequent changes pushed to the master branch (commits, pull requests, etc) will trigger this pipeline.
-   When you want to destroy the architecture:
    -   Go back to your repo locally where you cloned it.
    -   Commit a change where you comment the workflow named "deploy" and uncomment the workflow named "destroy" in the .circleci/config.yml.
    -   This will cause the CircleCI project to trigger a pipeline for the destroy job.

### Local Deploy (Less Fun)

-   After having git, docker, terraform, and the AWS CLI installed, run the following commands to deploy the app:
-   Clone this repo: `git clone https://github.com/pradeeptathineni/quest`
    -   Commit a change where you update the Makefile's variables :
        1. SERVICE (must be the same name as this repo)
        2. AWS_ACCOUNT_ID (your AWS account ID)
        3. REGION (your preferred AWS region to deploy in)
-   Configure your AWS CLI default profile: `aws configure`
-   When you want to deploy the architecture:
    -   Run `make local-deploy`
-   When you want to destroy the architecture:
    -   Run `make destroy`

#### PLEASE NOTE: If you delete the Terraform state bucket before you wipe the Terraform service architecture, you may be in a pickle that requires you to manually delete all those AWS resources. To avoid this, follow the automated steps defined here.

---

## Service Infrastructure

-   The quest's node.js app is deployed as a Docker image running on AWS ECS.

    -   It is loadbalanced over two availability zones and served over HTTP and HTTPS.
    -   HTTP traffic is rerouted to HTTPS.

-   CircleCI defines a CICD pipeline that will build a new Docker image, push it to ECR, force redeploy the ECS service, and apply new Terraform architecture changes.
    -   Terraform configuration and state files are versioned in separate buckets to maintain architecture history changes.
    -   This pipeline can be used for the preliminary and subsequent deployments.

## CICD Infrastructure

-   I created an AWS S3 bucket to serve as backend to this service's Terraform project state file (terraform.tfstate). This is a good practice for several reasons:
-   CircleCI runs a pipeline defined by .circleci/config.yml every time changes are pushed to the master branch of our repo.
-   Using a CircleCI virtual machine image of cimg/aws versus cimg/node and having to install aws cli allowed me to cut my pipeline runtime in half.

## Twelve Factor:

-   The Twelve-Factor methodology is a set of principles for building modern, scalable, and maintainable software applications. The factors include: codebase, dependencies, configuration, backing services, build, release, run, processes, port binding, concurrency, disposability, dev/prod parity, logs, and admin processes. These factors are intended to promote best practices in software development. By following these principles, developers can build applications that are easier to maintain, scale, and deploy, and that are adaptable to changing requirements and environments.

-   The application architecture of this quest app tries to accomplish the Twelve Factor practice in the following ways:

    1. Codebase: The application and its IaaC is saved in the version control system Github.
    2. Dependency management: The application has dependencies defined in its NPM package.json, which are installed during the building of the Docker image.
    3. Config: The configuration values for the application and its architecture are stored in variables that can be easily changed depending on the environment, increasing reusability and security.
    4. Backing services: The application uses AWS services like VPC, Security Group, ECS Cluster, ECS Task Definition, and Load Balancer.
    5. Build, release, run: Stages are separated as the application is built using Docker, released through Terraform, and run on the AWS infrastructure.
    6. Processes: The architecture runs as a containerized service in a serverless ECS cluster.
    7. Port binding: The architecture binds the container to port 3000 for the node.js app to communicate, and binds the loadbalancer to port 80 for HTTP and 443 for HTTPS to allow ingress web traffic.
    8. Concurrency: The architecture is designed to be scalable by running multiple instances of the application reachable by a loadbalancer.
    9. Disposability: The application, given being ran in AWS ECS, has the ability to be taken down, redeployed, and force redeployed at any time with no downtime over either region, as ECS will perform blue-green deployments in each region.
    10. Dev/prod parity: The architecture is deployed in the same way across different environments, using the same Terraform configuration but with different environment variables.
    11. Logs: The architecture uses a CloudWatch log group to monitor the containers.
    12. Admin processes: The architecture is managed using the Terraform configuration files and Terraform command line.

## Things I would have done differently or with more time

1. I did not use a methodology of Git commenting. Usually it's acceptable Git commenting practice to just describe what is being done. However, very often in Git projects that are company production services, we will see collaborators use a commit tagging convention of their own that allows them to better discern commits. This is a good practice for documentation and rollback purposes. A few examples of these that I could have used throughout my development are (https://www.freecodecamp.org/news/writing-good-commit-messages-a-practical-guide/):

    - feat: The new feature you're adding to a particular application
    - fix: A bug fix
    - style: Feature and updates related to styling
    - refactor: Refactoring a specific section of the codebase
    - test: Everything related to testing
    - docs: Everything related to documentation
    - chore: Regular code maintenance.

2. I felt that there should be CICD pipelines for two different types of deployments: 1) service deployments (changes to application or Dockerfile code), and 2) infrastructure deployments (changes to Terraform infrastructure). Ideally for this scenario, there would be some kind of logic to see that changes occurred in certain files, and according to that will a service deployment, infrastructure deployment, or both occur. To simplify this, I decided that the CICD will do the entire deployment every time we have changes committed and we've decided to redeploy our application (i.e. it's maintenance time at the company). This means Docker will build and tag a new image, push it to ECR, force a redeployment in ECS, and finally also apply any terraform architecture changes. The downside here is you may be waiting for things to happen that you shouldn't have to wait for, such as rebuilding and retagging an image that hasn't been changed. An upside to this is that the Docker image will be scanned for vulnerabilities every time there is a deploy, so on every deploy we can ensure we have the latest information on our application image's security posture. We can also have our pipeline service, such as AWS CodePipeline, CircleCI, or Jenkins, tag the image with the latest commit being deployed, so every deploy is related to an image uniquely identifiable by the commit.

3. ~~I would have liked to use CircleCI console to complete my testing, however I reached a blocker where the console would not allow me to view my projects. I feel like it was because I was fiddling with my CircleCI-Github connection. I made a CircleCI support ticket and hope to be contacted by them. Nevertheless, all the correct architecture and configuration for CircleCI to properly run deploys is defined in our quest project--it just needs testing.~~ CircleCI worked in my Safari browser, possibly because some Firefox or Chrome extension was blocking connections.

4. If I could figure out how to update my ECS task's image tag to anything I want whenever, then I would tag the built docker image of our service with the $CIRCLE_SHA value, which would be the commit of the current build. This would allow greater versioning control of our docker images instead of just writing over "latest" every time. I bet I could do this through aws cli. Use [update-service](https://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html) to update the task definition, perhaps with a newly created one. [register-task-definition](https://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html) and [deregister-task-definition](https://docs.aws.amazon.com/cli/latest/reference/ecs/deregister-task-definition.html).

5. There must be to be a better way of porting output variables between Terraform config files.

6. We can also try to lock down permissions to the most granular so that the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are not admin access. This was done for ease.

7. Something very valuable to accomplish next would be the use of multiple environments (development, test, production, etc) split between multiple AWS accounts, with different branches for each environment, each of which can be configured in CircleCI as their own CICD projects.

8. I would also like to use Route53 to route the loadbalancer DNS to a domain name of my own, also enabling me to host dev.domain-example.com and prod.domain-example.com spaces.

## Questions I was left with

### Q. Why do I not have to create an AWS target group for HTTPS protocol?

-   When I first deployed my architecture, I was creating one target group for both HTTP and HTTPS protocols, but it turned out assigning that HTTPS target group to the HTTPS listener would not work.
-   Turns out it was the listener that was of importance when configuring HTTPS for a target group.
-   I had to point the HTTPS listener to the same 'HTTP' target group.

### Q. Why must the AWS ECR repo name have to be the same as the image name?

-   My image name was formed as quest-app. My ECR repo at one point I named as quest-ecr-repo. I was unable to do a `docker push 310981538866.dkr.ecr.us-east-1.amazonaws.com/quest-ecr-repo:latest` as the push would cause retries, suggesting that the URL is not reachable
-   This worked once I made the two names the same.

### Q. How can I programmatically create an S3 bucket for a Terraform config file backend without it needing to be created first?

-   It must be created first because the "backend" block does not allow for variables. Each attribute must be supplied a hard string. Terraform is actively looking into if variables can be allowed here.
-   For now, the best I was able to do is create a /.state folder which has Terraform config files to create these backend buckets before we initialize and apply the terraform projects that use them as backends for tfstate.

### Q. Why does Terraform work in such a way that, if I want to use an S3 bucket as backend for my terraform.state file, the S3 bucket has to exist prior and cannot be created within the same Terraform configuration file?

-   This was the largest project logic changer for me, as in the very beginning I was thinking to keep another terraform project under .state/terraform that simply created the bucket that will be used as backend for the .service/terraform project.
-   I found out later in my CircleCI builds that I would need to save the state of this .state/terraform project too so I could retrieve its outputs from that same state file, namely an output called service_terraform_state_bucket which I would use to pass to `terraform init -backend-config="bucket=$service_terraform_state_bucket"`. This was my workaround to programatically creating a bucket for a backend, which refuses to take a variable name in its block.
-   Seeing that I was headed down a rabbit-hole of state bucket recursion, I thought why not just hard-code the bucket name, and even provide the same bucket name for the .state/terraform project backend? No need to get any output from some terraform.state file to programatically configure the backend in .service/terraform right? I could even use the same bucket to save the terraform.tfstate created by applying the .state/terraform project.
-   However this is when I had the big realization that if I don't need the .state/terraform project's terraform.state to have the output of the state bucket's name, there's no point of having the backend for it. So I'll just port over all the state bucket resources to my .service/terraform project where the backend uses that bucket resource.
-   Wrong, as terraform init, which initializes the connection to the backend, happens before a terraform apply, which would be the action to create the bucket.
-   The lesson learned: You just have to create a bucket beforehand. Don't use Terraform to create your backend bucket.
-   I mean, you can, but don't. Because you're going to end up using terraform init and terraform apply for creating the bucket resources every time, and terraform init not having any backend to refer to previous state changes would error out every subsequent time as the bucket already exists.
-   To fix this, you would need to use aws cli to see if the bucket exists, and if not then do the terraform init and apply.
-   With all this effort, I would rather just use the aws cli to find the bucket by hard-coded name, and if it doesn't exist then create it with the aws cli.
-   But seeing as I already wrote the terraform project for handling the state bucket creation, I opted to just use aws cli to check if the bucket exists and if not then perform the terraform apply and init.
-   The only major downside is that the bucket name is hard-coded in the .state/terraform/main.tf, .state/terraform/providers.tf, and .circleci/config.yml.
