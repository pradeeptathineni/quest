# A quest in the clouds

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

### Q. What is this quest?

It is a fun way to assess your cloud skills. It is also a good representative sample of the work we do at Rearc. Quest is a webapp made with node.js and golang.

### Q. So what skills should I have?

-   Public cloud: AWS, GCP, Azure.
    -   More than one cloud is a "good to have" but one is a "must have".
-   General cloud concepts, especially networking.
-   Containerization, such as: Docker, containerd, kubernetes
-   IaC (Infrastructure as code). At least some Terraform preferred.
-   Linux (or other POSIX OS).
-   VCS (Version Control System). Git is highly preferred.
-   TLS is a plus.

### Q. What do I have to do?

You may do all or some of the following tasks. Please read over the complete list before starting.

1. If you know how to use git, start a git repository (local-only is acceptable) and commit all of your work to it.
2. Use Infrastructure as Code (IaC) to the deploy the code as specified below.
    - Terraform is ideal, but use whatever you know, e.g. CloudFormation, CDK, Deployment Manager, etc.
3. Deploy the app in a container in any public cloud using the services you think best solve this problem.
    - Use `node` as the base image. Version `node:10` or later should work.
4. Navigate to the index page to obtain the SECRET_WORD.
5. Inject an environment variable (`SECRET_WORD`) in the Docker container using the value on the index page.
6. Deploy a load balancer in front of the app.
7. Add TLS (https). You may use locally-generated certs.

### Q. How do I know I have solved these stages?

Each stage can be tested as follows (where `<ip_or_host>` is the location where the app is deployed):

1. Public cloud & index page (contains the secret word) - `http(s)://<ip_or_host>[:port]/`
2. Docker check - `http(s)://<ip_or_host>[:port]/docker`
3. Secret Word check - `http(s)://<ip_or_host>[:port]/secret_word`
4. Load Balancer check - `http(s)://<ip_or_host>[:port]/loadbalanced`
5. TLS check - `http(s)://<ip_or_host>[:port]/tls`

### Q. Do I have to do all these?

You may do whichever, and however many, of the tasks above as you'd like. We suspect that once you start, you won't be able to stop. It's addictive. Extra credit if you are able to submit working entries for more than one cloud provider.

### Q. What do I have to submit?

1. Your work assets, as one or both of the following:
    - A link to a hosted git repository.
    - A compressed file containing your project directory (zip, tgz, etc). Include the `.git` sub-directory if you used git.
2. Proof of completion, as one or both of the following:
    - Link(s) to hosted public cloud deployment(s).
    - One or more screenshots showing, at least, the index page of the final deployment in one or more public cloud(s) you have chosen.
3. An answer to the prompt: "Given more time, I would improve..."
    - Discuss any shortcomings/immaturities in your solution and the reasons behind them (lack of time is a perfectly fine reason!)
    - **This may carry as much weight as the code itself**

Your work assets should include:

-   IaC files, if you completed that task.
-   One or more Dockerfiles, if you completed that task.
-   A sensible README or other file(s) that contain instructions, notes, or other written documentation to help us review and assess your submission.
    -   **Note** - the more this looks like a finished solution to deliver to a customer, the better.

### Q. How long do I need to host my submission on public cloud(s)?

You don't have to at all if you don't want to. You can run it in public cloud(s), grab a screenshot, then tear it all down to avoid costs.

If you _want_ to host it longer for us to view it, we recommend taking a screenshot anyway and sending that along with the link. Then you can tear down the quest whenever you want and we'll still have the screenshot. We recommend waiting no longer than one week after sending us the link before tearing it down.

### Q. What if I successfully complete all the challenges?

We have many more for you to solve as a member of the Rearc team!

### Q. What if I find a bug?

Awesome! Tell us you found a bug along with your submission and we'll talk more!

### Q. What if I fail?

There is no fail. Complete whatever you can and then submit your work. Doing _everything_ in the quest is not a guarantee that you will "pass" the quest, just like not doing something is not a guarantee you will "fail" the quest.

### Q. Can I share this quest with others?

No. After interviewing, please change any solutions shared publicly to be private.
