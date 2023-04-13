# Quest Discussion

## Service Infrastructure

-   The quest's node.js app is deployed as a Docker image running on AWS ECS.

    -   It is loadbalanced over two availability zones and served over HTTP and HTTPS.
    -   HTTP traffic is rerouted to HTTPS.

-   CircleCI defines a CICD pipeline that will build a new Docker image, push it to ECR, force redeploy the ECS service, and apply new Terraform architecture changes.
    -   Terraform configuration and state files are versioned in separate buckets to maintain architecture history changes.
    -   This pipeline can be used for the preliminary and subsequent deployments.

## CICD Infrastructure

-   I created an AWS S3 bucket for the Terraform configuration files and another for the Terraform state files. This is a good practice for several reasons:
    -   Separation of Concerns: Keeping the Terraform configuration files and state files separate can help reduce the risk of accidentally overwriting or deleting critical files. It also makes it easier to manage access control for each bucket separately.
    -   Versioning: It's a good practice to enable versioning on S3 buckets that store critical files. However, having both configuration files and state files in the same bucket could lead to confusion when trying to identify the right version of a specific file.
    -   Performance: Terraform state files can grow quite large, especially for larger infrastructures. Storing them in a separate S3 bucket can help prevent performance issues with the bucket used for configuration files.

## Twelve Factor:

-   The Twelve-Factor methodology is a set of principles for building modern, scalable, and maintainable software applications. The factors include: codebase, dependencies, configuration, backing services, build, release, run, processes, port binding, concurrency, disposability, dev/prod parity, logs, and admin processes. These factors are intended to promote best practices in software development. By following these principles, developers can build applications that are easier to maintain, scale, and deploy, and that are adaptable to changing requirements and environments. The 12 factors can be described as the following (https://dzone.com/articles/12-factor-app-principles-and-cloud-native-microser):

    1. Codebase: One codebase tracked in revision control, many deploys. `Each application should have a single codebase that is tracked in a version control system, such as Git. This allows for easy collaboration and versioning.`
    2. Dependencies: Explicitly declare and isolate dependencies. `All dependencies for an application should be explicitly declared and isolated using a package manager or other tools. This helps to ensure that the application can be easily built and deployed in different environments.`
    3. Configuration: Store configuration in the environment. `Configuration information should be stored in environment variables, rather than hard-coded in the application code. This allows for easy configuration changes without the need to recompile the code.`
    4. Backing services: Treat backing services as attached resources. `External services, such as databases or messaging queues, should be treated as attached resources that can be easily swapped out or scaled independently. This helps to ensure that the application can be easily adapted to changing business requirements.`
    5. Build, release, run: Strictly separate build and run stages. `The build, release, and run stages of an application should be strictly separated, with each stage having its own environment and tools. This helps to ensure that the application can be easily built, tested, and deployed in different environments.`
    6. Processes: Execute the app as one or more stateless processes. `An application should be designed to run as a set of stateless processes, which can be easily scaled up or down depending on the demand. This helps to ensure that the application can handle changing user loads without downtime or performance issues.`
    7. Port binding: Export services via port binding. `An application should export its services via a network port, rather than relying on internal function calls or library dependencies. This allows for easy communication with other services and systems.`
    8. Concurrency: Scale out via the process model. `An application should be designed to scale out by running multiple instances of the same process, rather than relying on multi-threading or other techniques. This helps to ensure that the application can handle high loads and maintain performance.`
    9. Disposability: Maximize robustness with fast startup and graceful shutdown. `An application should be designed to start up quickly and shut down gracefully, in order to minimize downtime and maximize uptime. This helps to ensure that the application can be easily maintained and updated.`
    10. Dev/prod parity: Keep development, staging, and production as similar as possible. `An application should be designed to work the same way in development, staging, and production environments, in order to minimize differences and reduce the risk of errors. This helps to ensure that the application can be easily tested and deployed in different environments.`
    11. Logs: Treat logs as event streams. `An application should generate logs as a stream of events, which can be easily collected, analyzed, and searched. This helps to ensure that the application can be easily monitored and debugged.`
    12. Admin processes: Run admin/management tasks as one-off processes. `Administrative tasks, such as database migrations or backups, should be run as one-off processes, rather than being integrated into the application code. This helps to ensure that the application code remains focused on its core functionality.`

-   In addition to the main factors, there are a few other important points to keep in mind:

    -   Portability: Applications should be designed to be as portable as possible, meaning that they can be easily moved between different infrastructure providers or hosting environments.
    -   Stateless architecture: Applications should be designed to be stateless whenever possible, meaning that they don't rely on stored state information. This makes it easier to scale and maintain the application.
    -   Automation: As much of the deployment and management process as possible should be automated, in order to minimize human error and make it easier to manage the application at scale.
    -   Testability: Applications should be designed to be easily testable, with automated testing built into the development process. This helps to ensure that the application is reliable and performs as expected.

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

## Questions I was left with

### Q. Why do I not have to create an AWS target group for HTTPS protocol?

-   When I first deployed my architecture, I was creating one target group for both HTTP and HTTPS protocols, but it turned out assigning that HTTPS target group to the HTTPS listener would not work.
-   Turns out it was the listener that was of importance when configuring HTTPS for a target group.
-   I had to point the HTTPS listener to the same 'HTTP' target group.
