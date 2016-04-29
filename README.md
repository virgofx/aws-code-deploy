# AWS Code Deploy Executer

[![Software License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://raw.githubusercontent.com/techpivot/phalcon-ci-installer/master/LICENSE)


This script deploys applications with the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) service. This script has been adapted to be easily portable and configurable via environment variables such that it can be incorporated within CI services that do not natively include support for Code Deploy. Additionally, this script includes additional functionality described below that is typically not included in out-of-box Code Deploy CI systems. For more information, refer to the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) documentation or
the [AWS CLI API](http://docs.aws.amazon.com/cli/latest/reference/deploy/index.html).

#### Fork notes:

This fork has files added to it to make it suitable for running as a step for wercker.com.
To use this on Wercker, add a step like so:

    - maestrohealthcaretechnologies/aws-code-deploy:
        application-name: my-codedeploy-app
	s3-bucket: my-s3-bucket
	deployment-group-name: $WERCKER_DEPLOYTARGET_NAME
	code-deploy-region: us-east-1
	s3-key-prefix: $WERCKER_GIT_REPOSITORY/$WERCKER_DEPLOYTARGET_NAME
	s3-sse: true
	s3-filename: $WERCKER_DEPLOY_ID.zip
	app-source: $WERCKER_ROOT
	revision-description: Git commit $WERCKER_GIT_COMMIT
	deployment-description: Deployed by Wercker on $(date)

Each parameter corresponds to the environment variable described below, without the "AWS_CODE_DEPLOY" prefix; the other parameters described below can also be used in a similar manner. Only the first two options are required; the rest will default to values based on Wercker environment variables, as shown above.

#### Features:
 * Compression of source contents
 * Ability to limit the number of stored revisions by a key prefix to help reduce S3 total file size
 * Server side encryption for revisions
 * Full diagnostic output from failed instances

#### Operating Systems Supported:
 * Debian 7
 * Ubuntu 12.04
 * Ubuntu 14.04


## Sample Output

```bash

Step 1: Checking Dependencies
✔ Dependencies met (aws: aws-cli/1.8.12 Python/2.7.6 Linux/3.14.28-031428-generic).

Step 2: Configuring AWS
✔ AWS Access Key already configured.
✔ AWS Secret Access Key already configured.
✔ Successfully configured AWS default region.

Step 3: Checking Application
➜ aws deploy get-application --application-name TechPivot
✔ Application "TechPivot" already exists

Step 4: Checking Deployment Config
➜ aws deploy get-deployment-config --deployment-config-name CodeDeployDefault.AllAtOnce
✔ Deployment config "CodeDeployDefault.AllAtOnce" already exists

Step 5: Checking Deployment Group
➜ aws deploy get-deployment-group --application-name TechPivot --deployment-group-name www.techpivot.net
✔ Deployment group "www.techpivot.net" already exists for application "TechPivot"

Step 6: Compressing Source Contents
➜ cd "/home/ubuntu/deploy" && zip -rq "/tmp/729#a4d2fa4.zip" .
✔ Successfully compressed "/home/ubuntu/deploy" (57M) into "729#a4d2fa4.zip" (18M)

Step 7: Copying Bundle to S3
➜ aws s3 cp --sse "/tmp/729#a4d2fa4.zip" "s3://techpivot-codedeploy/www/729#a4d2fa4.zip"
✔ Successfully copied bundle "729#a4d2fa4.zip" to S3

Step 8: Limiting Deploy Revisions per Bucket/Key

Checking bucket/key to limit total revisions at 10 files ...
➜ aws s3 ls "s3://techpivot-codedeploy/www/"

Removing oldest 1 file(s) ...
➜ aws s3 rm "s3://techpivot-codedeploy/www/713#1ef9317.zip"
✔ Successfuly removed 1 file(s)

Step 9: Registering Revision
➜ aws deploy register-application-revision --application-name "TechPivot" --s3-location bucket=techpivot-codedeploy,bundleType=zip,key=www/729#a4d2fa4.zip --description "master (#a4d2fa4)"
✔ Registering revision succeeded

Step 10: Creating Deployment
➜ aws deploy create-deployment --application-name TechPivot --deployment-config-name CodeDeployDefault.AllAtOnce --deployment-group-name www.techpivot.net --s3-location bucket=techpivot-codedeploy,bundleType=zip,key=www/729#a4d2fa4.zip --description "Deployed via CircleCI on Sun Nov  8 23:32:30 UTC 2015"
✔ Successfully created deployment: "d-CDR1HA75C"

Note: You can follow your deployment at: https://console.aws.amazon.com/codedeploy/home#/deployments/d-CDR1HA75C

Deployment Overview

Monitoring deployment "d-CDR1HA75C" for "TechPivot" on deployment group www.techpivot.net ...
➜ aws deploy get-deployment --deployment-id "d-CDR1HA75C"


Status  | In Progress: 0  | Pending: 0  | Skipped: 0  | Succeeded: 1  | Failed: 0  |
✔ Deployment of application "TechPivot" on deployment group "www.techpivot.net" succeeded
```


## How to Include In Your Project

1. Via Composer (For PHP Projects)
  * Include in `composer.json` as follows:

       ```json
       "require-dev" : {
            "techpivot/aws-code-deploy": "~1.0"
        }
        ```
  * The file can then be executed from the /vendor/bin directory: `bash vendor/bin/aws-code-deploy.sh`


## Variables

```
AWS_CODE_DEPLOY_KEY
AWS_CODE_DEPLOY_SECRET
AWS_CODE_DEPLOY_REGION
AWS_CODE_DEPLOY_APPLICATION_NAME
AWS_CODE_DEPLOY_DEPLOYMENT_CONFIG_NAME
AWS_CODE_DEPLOY_MINIMUM_HEALTHY_HOSTS
AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME
AWS_CODE_DEPLOY_SERVICE_ROLE_ARN
AWS_CODE_DEPLOY_EC2_TAG_FILTERS
AWS_CODE_DEPLOY_AUTO_SCALING_GROUPS
AWS_CODE_DEPLOY_APP_SOURCE
AWS_CODE_DEPLOY_S3_BUCKET
AWS_CODE_DEPLOY_S3_KEY_PREFIX
AWS_CODE_DEPLOY_S3_FILENAME
AWS_CODE_DEPLOY_S3_LIMIT_BUCKET_FILES
AWS_CODE_DEPLOY_S3_SSE
AWS_CODE_DEPLOY_REVISION_DESCRIPTION
AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION
```

## Examples

### CircleCI

**circle.yml**
```
machine:

  environment:
    DEPLOY_DIR: $HOME/deploy
    
    # We are defining the $AWS_CODE_DEPLOY_KEY and $AWS_CODE_DEPLOY_SECRET in the CircleCI Project Settings >
    # AWS Permissions which automatically configure these for use via aws cli and are automatically read
    # via aws-code-deploy.sh. Alternatively, these could be specified securely (not via project code) using 
    # the CircleCI Environment Variables CircleCI control panel.
    AWS_CODE_DEPLOY_REGION: us-west-2
    AWS_CODE_DEPLOY_APPLICATION_NAME: "Company Website"
    AWS_CODE_DEPLOY_DEPLOYMENT_CONFIG_NAME: CodeDeployDefault.AllAtOnce
    AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME: "www.my-company.com"
    AWS_CODE_DEPLOY_SERVICE_ROLE_ARN: "arn:aws:iam::XXXXXXXXXXXXX:role/my-company-codedeploy"
    AWS_CODE_DEPLOY_EC2_TAG_FILTERS: "Key=Type,Value=www,Type=KEY_AND_VALUE"
    AWS_CODE_DEPLOY_APP_SOURCE: $HOME/deploy
    AWS_CODE_DEPLOY_S3_FILENAME: "${CIRCLE_BUILD_NUM}#${CIRCLE_SHA1:0:7}.zip"
    AWS_CODE_DEPLOY_S3_BUCKET: my-company-codedeploy-us-west-2
    AWS_CODE_DEPLOY_S3_KEY_PREFIX: /www
    AWS_CODE_DEPLOY_S3_LIMIT_BUCKET_FILES: 10
    AWS_CODE_DEPLOY_S3_SSE: true
    AWS_CODE_DEPLOY_REVISION_DESCRIPTION: "${CIRCLE_BRANCH} (#${CIRCLE_SHA1:0:7})"
    AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION: "Deployed via CircleCI on $(date)"

# ...

deployment:
  production:
    branch: master
    commands:
      - bash vendor/bin/aws-code-deploy.sh
```
    
### TravisCI

### Manual


## IAM Requirements

In order for the script to execute successfully, the specified AWS credentials must be granted the required 
IAM privileges for the corresponding actions. Since various steps of this script are optional it allows for
flexibility in creating policies that apply the principle of least privilege. Two common examples are described 
below. In general, the script needs access to the following (depending on parameters):

  1. Code Deploy - Verifying Application, Creating Application, Creating Revisions
  2. Code Deploy Deployment - Creating Deployment, Creating Deployment Group, Listing Instances
  3. S3 - Uploading bundle to S3, Deleting Old Revisions
  

#### Wildcard Access
This may be best for first time users with 


#### Explicit Access with Full Functionality
  * 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateApplication",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": [
                "arn:aws:codedeploy:us-west-2:XXXXXXXXXXXX:application:TechPivot"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:CreateDeploymentGroup",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentGroup",
                "codedeploy:GetDeploymentInstance",
                "codedeploy:ListDeploymentInstances"
            ],
            "Resource": [
                "arn:aws:codedeploy:us-west-2:XXXXXXXXXXXX:deploymentgroup:TechPivot/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:GetDeploymentConfig"
            ],
            "Resource": [
                "arn:aws:codedeploy:us-west-2:XXXXXXXXXXXX:deploymentconfig:CodeDeployDefault.OneAtATime",
                "arn:aws:codedeploy:us-west-2:XXXXXXXXXXXX:deploymentconfig:CodeDeployDefault.HalfAtATime",
                "arn:aws:codedeploy:us-west-2:XXXXXXXXXXXX:deploymentconfig:CodeDeployDefault.AllAtOnce"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::techpivot-codedeploy-us-west-2/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListObjects"
            ],
            "Resource": [
                "arn:aws:s3:::techpivot-codedeploy-us-west-2"
            ]
        }
    ]
}
```

## Detailed Workflow & Variable Information

#### Step 1: Checking Dependencies

The following executables are installed:
  * python-pip
  * aws

#### Step 2: [Configuring AWS](http://docs.aws.amazon.com/cli/latest/reference/configure/index.html)

This step ensures that configuration parameters for AWS CLI are properly set.

Environment Variables:

* `AWS_CODE_DEPLOY_KEY` (optional): AWS Access Key ID. If not already configured in **aws** cli, this is required.
* `AWS_CODE_DEPLOY_SECRET` (optional): AWS Secret Access Key. If not already configured in **aws** cli, this is required.
* `AWS_CODE_DEPLOY_REGION` (optional): Default region name

#### Step 3: [Checking Application](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html)

This step ensures the application exists within Code Deploy. If it does not exist, it will attempt to create the application with the specified name.

Environment Variables:

* `AWS_CODE_DEPLOY_APPLICATION_NAME` (required): Name of the application to deploy

#### Step 4: [Deployment Config](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html) (optional)

This step ensures the specified deployment configuration exists for the application. Defining a custom configuration is *optional* because you can use the deployment strategy already defined in Code Deploy.

Environment Variables:

* `AWS_CODE_DEPLOY_DEPLOYMENT_CONFIG_NAME` (optional): Deployment config name. By default: _CodeDeployDefault.OneAtATime_. Built-in options:
    * CodeDeployDefault.OneAtATime
    * CodeDeployDefault.AllAtOnce
    * CodeDeployDefault.HalfAtATime
* `AWS_CODE_DEPLOY_MINIMUM_HEALTHY_HOSTS` (optional): The minimum number of healthy instances during deployment. By default: _type=FLEET_PERCENT,value=75_

#### Step 5: [Deployment Group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html)

This step ensures the deployment group exists within the specified application. If it does not exist, the script will attempt to create the group using the name and defined service role ARN.

Environment Variables:

* `AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME` (required): Deployment group name
* `AWS_CODE_DEPLOY_SERVICE_ROLE_ARN` (required): Service role arn giving permissions to use Code Deploy when creating a deployment group
* `AWS_CODE_DEPLOY_EC2_TAG_FILTERS` (optional): EC2 tags to filter on when creating a deployment group. Specify as a string with the following comma separated keys:
    * **Key** *string*
    * **Value** *string*
    * **Type** *string* - Either: `KEY_ONLY` or `VALUE_ONLY` or `KEY_AND_VALUE`
    
    For example: `AWS_CODE_DEPLOY_EC2_TAG_FILTERS="Key=Type,Value=www,Type=KEY_AND_VALUE"`

* `AWS_CODE_DEPLOY_AUTO_SCALING_GROUPS` (optional): Auto Scaling groups when creating a deployment group

Required IAM Access:
```
    "codedeploy:CreateDeploymentGroup",
    "codedeploy:GetDeploymentGroup"
```

#### Step 6: Compressing Source

This step compresses the specified source directory as a zip file in preparation for uploading to S3. This is useful for application deployments that use unique file names per revision. This helps limit the transfer to and from S3 during deployment.

Environment Variables:

* `AWS_CODE_DEPLOY_APP_SOURCE` (required): Specifies the root source contents of the application. The `appspec.yml` should exist within this directory. If not specified, the script will use the current working directory.
* `AWS_CODE_DEPLOY_S3_FILENAME` (required): The destination name within S3. Note that this should **not** include any prefix keys as these are defined elsewhere. A recommended good practice would be to use a combination of the CI build number with the git short revision. (e.g. "100#c3a5fea.zip")

#### Step 7: [Pushing to S3](http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html)

This step consists to push the application to S3.

Environment Variables:

* `AWS_CODE_DEPLOY_S3_BUCKET` (required): The name of the S3 bucket to deploy the revision
* `AWS_CODE_DEPLOY_S3_KEY_PREFIX` (optional): A prefix to use for the file key. It's highly recommended to structure a bucket with a prefix per deployment group. This allows to limit stored revisions per deployment group. Note: A leading or trailing slash is not required.  

  For example:

  ```
  AWS_CODE_DEPLOY_S3_BUCKET="my-bucket-test"
  AWS_CODE_DEPLOY_S3_KEY_PREFIX="production-www"
  AWS_CODE_DEPLOY_S3_FILENAME="100#c3a5fea.zip"

  # The resulting stored file would exist at s3://my-bucket-test/production-www/100#c3a5fea.zip
  ```

#### Step 8: Limiting Deploy Revisions per Bucket/Key

This step ensures that applications with high revision/commit volume with unique filenames can remove
old revisions to help limit the size of the container. Large teams can quickly fill S3 with multiple
TBs/day depending on the projects. Since deployments typically don't need to store that many versions
backwards, this step will ensure that only N revisions exist, removing oldest revisions upon deploy.

> Note: If a limit is specified, the IAM permissions described below will need to be granted for the 
specific s3://bucket/(key).

Environment Variables:
* `AWS_CODE_DEPLOY_S3_LIMIT_BUCKET_FILES` (optional): Number of revisions to limit. If 0, unlimited. By default: 0

Required IAM Access:
* Wildcard: `s3:DeleteObject`, `s3:GetObject`
* Bucket Policy: `s3:ListBucket`, `s3:ListObjects`


#### Step 9: [Registering Revision](http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html)

This step registers a code deploy revision for the uploaded file to the specified application/deployment group.

Environment Variables:

* `AWS_CODE_DEPLOY_REVISION_DESCRIPTION` (optional): A description that is stored within AWS Code Deploy that stores information about the specific revision. Typically, the revision details would store information specific to the commit/CI/build details.


#### Step 10: [Creating Deployment](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html)

This step deploys the application revision using the defined deployment settings across all hosts that match the deployment group.

Environment Variables:

* `AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION` (optional): A description that is stored within AWS Code Deploy that stores information about the specific revision.

#### Monitor Deployment

This step monitors the deployment and logs information about the overall status as well as any failed instance statuses.

Environment Variables:

* `AWS_CODE_DEPLOY_DEPLOYMENT_OVERVIEW` (optional): Boolean that specifies whether to log detailed information about the status of the deployment. By Default: _true_
