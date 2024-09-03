# CI/CD Pipeline for Automated Deployment and Rollback on AWS ECS
## Overview
### This repository demonstrates a CI/CD pipeline for automating the deployment of a simple web application to AWS ECS (Elastic Container Service) using GitHub Actions. The pipeline is designed to:

1. **Build an optimized Docker image** using a multi-stage build with Nginx as a reverse proxy.
2. **Push the Docker image** to Amazon Elastic Container Registry (ECR).
3. **Deploy the application** on AWS ECS.
4. **Perform integration tests** to ensure the deployment is successful.
5. **Implement rollback functionality** in case the integration tests fail.

## Prerequisites
### For this pipeline ensure the following prerequisites are met :-

1. **AWS Account :-** Access to AWS services such as ECS, ECR and IAM.
2. **GitHub Repository :-** A GitHub repository containing the application's source code.
3. **GitHub Actions Secrets :-** The following secrets should be configured in your GitHub repository :-
* **AWS_ACCESS_KEY_ID :-** Your AWS Access Key ID.
* **AWS_SECRET_ACCESS_KEY :-** Your AWS Secret Access Key.

## CI/CD Pipeline Overview
# 1. Checkout Code
The pipeline begins by checking out the code from the GitHub repository :-
```
- name: Checkout code
  uses: actions/checkout@v3
```
# 2. Build Docker Image
A multi-stage Dockerfile is used to build a small and efficient image. The stages include :-

* **Stage 1 :-  Build :** Compile and build the application.
* **Stage 2 :-  Production Image :** Copy the build artifacts and set up Nginx as a reverse proxy.
Dockerfile :-

```
# Stage 1: Build the application using an Apache server
FROM ubuntu as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y apache2 apache2-utils \
    && apt-get clean

RUN echo "Hello Fam From Sudha Yadav" > /var/www/html/index.html

# Stage 2: Set up Nginx as a reverse proxy
FROM nginx:alpine

# Copy the built application from the first stage
COPY --from=build /var/www/html /usr/share/nginx/html

# Remove the default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Add your custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
# 3. Push Docker Image to ECR
The Docker image is tagged and pushed to the Amazon ECR repository :-
```
- name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Build a docker container and push it to ECR so that it can be deployed to ECS.
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
```
![repo](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/repo.png)
![image](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/image.png)
# 4. Fill new image
```
- name: Fill in the new image ID in the Amazon ECS task definition
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.ECS_TASK_DEFINITION }}
        container-name: ${{ env.CONTAINER_NAME }}
        image: ${{ steps.build-image.outputs.image }}
```
# 5. Deploy to ECS
The ECS service is updated with the new image. The deployment ensures zero downtime by managing rolling updates :-
```
- name: Deploy to Amazon ECS
  uses: aws-actions/amazon-ecs-deploy-task-definition@v1
  with:
    task-definition: ${{ secrets.ECS_TASK_DEFINITION }}
    service: ${{ secrets.ECS_SERVICE_NAME }}
    cluster: ${{ secrets.ECS_CLUSTER_NAME }}
    wait-for-service-stability: true
```
![cluster](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/cluster.png)
![service](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/service.png)
![task](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/task.png)
# 6. Integration Tests
Post-deployment, integration tests are run to verify the application's functionality :-
```
- name: Run integration tests
  run: |
    curl -f http://my-app-url/ || exit 1
```
# 7. Rollback on Failure
If the integration tests fail, the pipeline automatically rolls back to the previous stable version :-
```
- name: Rollback on failure
  if: failure()
  run: |
    # Rollback logic here
    aws ecs update-service --cluster ${{ secrets.ECS_CLUSTER_NAME }} --service ${{ secrets.ECS_SERVICE_NAME }} --force-new-deployment
```

# Repository URL
https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS.git

# Pipeline Execution Snapshots
# 1. Task Definition
![TD](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/task-definition.png)
# 2. Cluster Overview
![CO](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS/blob/main/images/cluster-overview.png)
# 3. Deploy Summary
![Deploy](https://github.com/sudhajobs0107/cicd-GitHub-Actions-2-AWS-ECS)
# Conclusion
This CI/CD pipeline provides a robust solution for automating the deployment and management of applications on AWS ECS. With integrated testing and rollback features, it ensures that your application remains reliable and resilient in production.
