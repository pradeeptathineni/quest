# Quest Discussion

## Service Infrastructure

-   The quest's node.js app is deployed as a Docker image running on AWS ECS.

    -   It is loadbalanced over two availability zones and served over HTTP and HTTPS.
    -   HTTP traffic is rerouted to HTTPS.

-   CircleCI defines a CICD pipeline that will build a new Docker image, push it to ECR, force redeploy the ECS service, and apply new Terraform infrastructure changes.

    -   Terraform state file is saved and versioned in S3 to have infrastructure history.
    -   This pipeline can be used for the preliminary and subsequent deployments.

-   The instructions in the README.ms here also define a method of local deploy and maintenance.

## CICD Infrastructure

-   I created an AWS S3 bucket to serve as backend to this service's Terraform project state file (terraform.tfstate).
-   CircleCI runs a pipeline defined by .circleci/config.yml every time changes are pushed to the master branch of our repo.
-   Using a CircleCI virtual machine image of cimg/aws versus cimg/node and having to install aws cli, I cut my pipeline runtime in half.

## Security

-   We use multiple subnets within the VPC to create network segmentation and isolate different parts of the infrastructure.
-   Security groups are used to restrict incoming and outgoing traffic to only necessary ports and IP ranges.
-   The ECR repository is private by default, which helps to protect the Docker image from unauthorized access.
-   The ECS instances are placed in a private subnet with no internet gateway attached. This helps to protect the instances from unauthorized access from the internet.
-   The application loadbalancer is used to distribute incoming traffic to the ECS instances, and it is configured to terminate SSL/TLS connections using a certificate from AWS Certificate Manager (ACM). This ensures that the traffic between the client and the load balancer is encrypted in transit.
-   The ECS service uses AWS Fargate to run the containers in a serverless environment, which can help reduce the risk of server-level attacks.
-   An AWS WAF protects the loadbalancer against any traffic that is not from the USA only. This was a design choice to limit and secure traffic in a simple yet very effective way.

# Availability

-   Container logging is configured for the ECS tasks to track and monitor activity within those containers. These logs can be used to identify and investigate security incidents.
-   The ECS service is configured with two availability zones to ensure that the application is highly available even if one of the availability zones becomes unavailable.
-   The application loadbalances distributes traffic evenly across the ECS instances, which helps to ensure that the application remains available even if one of the instances becomes unavailable.
-   The ECS service is configured with a desired count and a maximum count of tasks (containers hosting our web server code), which allows the service to automatically scale up or down based on traffic demand. This helps to ensure that the application can handle a large volume of traffic without becoming unavailable.

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

1. I did not use a consistent methodology of Git commenting. Usually it's acceptable Git commenting practice to just describe what is being done. However, very often in Git projects that are company production services, we will see collaborators use a commit tagging convention of their own that allows them to better discern commits. This is a good practice for documentation and rollback purposes. A few examples of these that I could have used throughout my development are (https://www.freecodecamp.org/news/writing-good-commit-messages-a-practical-guide/):

    - feat: The new feature you're adding to a particular application
    - fix: A bug fix
    - style: Feature and updates related to styling
    - refactor: Refactoring a specific section of the codebase
    - test: Everything related to testing
    - docs: Everything related to documentation
    - chore: Regular code maintenance.

2. I felt that there should be a separation of jobs into two CICD pipelines for two different types of deployments: 1) service deployments (changes to application or Dockerfile code), and 2) infrastructure deployments (changes to Terraform infrastructure). Ideally for this scenario, there would be some kind of logic to see that changes occurred in certain files, and according to that will a service deployment, infrastructure deployment, or both occur. To simplify this, I decided that the CICD will do the entire deployment every time we have changes committed and we've decided to redeploy our application (i.e. it's maintenance time at the company). This means Docker will build and tag a new image, push it to ECR, force a redeployment in ECS, and finally also apply any terraform architecture changes. The downside here is you may be waiting for things to happen that you shouldn't have to wait for, such as rebuilding and retagging an image that hasn't been changed. An upside to this is that the Docker image will be scanned for vulnerabilities every time there is a deploy, so on every deploy we can ensure we have the latest information on our application image's security posture.

3. I would have CircleCI also tag the image with the latest commit being deployed, so every CICD deploy is related to an image uniquely identifiable by the commit.

4. If I could figure out how to update my ECS task's image tag to anything I want whenever, then I would tag the built docker image of our service with the $CIRCLE_SHA value only instead of "latest", which would be the commit of the current build. This would allow greater granularity of our docker images instead of just versioning over the "latest" image every time. I bet I could do this through aws cli. Use [update-service](https://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html) to update the task definition, perhaps with a newly created one. [register-task-definition](https://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html) and [deregister-task-definition](https://docs.aws.amazon.com/cli/latest/reference/ecs/deregister-task-definition.html).

5. There must be to be a better way of porting output variables between Terraform config files.

6. We can also try to lock down permissions to the most granular so that the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are not admin access. This was done for ease. Different resources should be defined with access permission according to their organizational unit. For example, the ECR repository can be further secured by using AWS IAM roles and policies to restrict access to specific users or roles.

7. Something very valuable to accomplish next would be the use of multiple environments (development, test, production, etc) split between multiple AWS accounts, with different branches for each environment, each of which can be configured in CircleCI as their own CICD projects.

8. I would also like to use Route53 to route the loadbalancer DNS to a domain name of my own, also enabling me to host dev.domain-example.com and prod.domain-example.com spaces.

9. I would enable auto-scaling for the ECS service, so that it may scale up and down automatically as needed

I would accomplish the below if project budget and constraints permit:

10. I would create an S3 bucket and turn on VPC flow logs for the VPC holding our service.

11. ~~I would AWS WAF to implement rules that can help protect our service from common web-based attacks, such as SQL injection and cross-site scripting (XSS). Similarly, I would implement a NACL on the VPC to further restrict access, for example from known attackers.~~

12. I would have the ECS service bring up 4 instances, 2 per AZ, instead of just 2 total.

13. I would enable AWS Config so I can have metrics on configuration changes to my AWS resources.

14. I would implement subnet-level encryption to encrypt data at rest within our public subnets, using tools like S3 Server-Side Encryption or AWS KMS to manage the encryption keys.

15. Consider increasing the availability and performance of the service by implementing AWS Global Accelerator on the loadbalancer.

16. I would use AWS Shield to protect the service from distributed denial-of-service (DDoS) attacks.

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
-   However this is when I had the big realization that if I don't need the .state/terraform project's terraform.state to have the output of the state bucket's name, there's no point of having the backend for it. So I thought to just port over all the state bucket code into the .service Terraform config and initialize it from there. Since the bucket name is hard-coded, this should work right?
-   Wrong, as terraform init, which initializes the connection to the backend, happens before a terraform apply, which would be the action to create the bucket.
-   The lesson learned: You just have to create a bucket beforehand.
-   I opted to just use aws cli to check if the bucket exists and if not then perform the state config terraform apply and init.
-   The only major downside is that the bucket name is hard-coded in the .state/terraform/main.tf, .state/terraform/providers.tf, and .circleci/config.yml.
