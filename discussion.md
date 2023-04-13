# Quest Discussion

## Service Infrastructure

## CICD Infrastructure

### Q. Why did you use two separate S3 buckets for Terraform configuration and state files?

-   I created one for the Terraform configuration files and another for the Terraform state files. This is a good practice for several reasons:

    -   Separation of Concerns: Keeping the Terraform configuration files and state files separate can help reduce the risk of accidentally overwriting or deleting critical files. It also makes it easier to manage access control for each bucket separately.

    -   Versioning: It's a good practice to enable versioning on S3 buckets that store critical files. However, having both configuration files and state files in the same bucket could lead to confusion when trying to identify the right version of a specific file.

    -   Performance: Terraform state files can grow quite large, especially for larger infrastructures. Storing them in a separate S3 bucket can help prevent performance issues with the bucket used for configuration files.

## Things I would have done differently or with more time

-   I did not use a methodology of Git commenting. Usually it's acceptable Git commenting practice to just describe what is being done. However, very often in Git projects that are company production services, we will see collaborators use a commit tagging convention of their own that allows them to better discern commits. This is a good practice for documentation and rollback purposes. A few examples of these that I could have used throughout my development are (https://www.freecodecamp.org/news/writing-good-commit-messages-a-practical-guide/):

    -   feat: The new feature you're adding to a particular application
    -   fix: A bug fix
    -   style: Feature and updates related to styling
    -   refactor: Refactoring a specific section of the codebase
    -   test: Everything related to testing
    -   docs: Everything related to documentation
    -   chore: Regular code maintenance.

## Questions I was left with

### Q. Why do I not have to create a target group for HTTPS protocol?

-   When I first deployed my architecture, I was creating one target group for both HTTP and HTTPS protocols, but it turned out assigning that HTTPS target group to the HTTPS listener would not work.
-   Turns out it was the listener that was of importance when configuring HTTPS for a target group.
-   I had to point the HTTPS listener to the same 'HTTP' target group.
