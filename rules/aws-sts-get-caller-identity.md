## AWS - Resolve account/region

Never hardcode or pass in the AWS account ID / region — resolve them natively from the tool you're using so a project
works reliably across every account and region it deploys into.

### CloudFormation

Don't declare parameters for the account ID / region. Use the built-in pseudo parameters `AWS::AccountId` and
`AWS::Region` — they always resolve to the account and region the stack is deployed into.

```yaml
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'my-app-${AWS::AccountId}-${AWS::Region}'
```

### SAM

SAM is a superset of CloudFormation, so the same pseudo parameters apply — reach for `AWS::AccountId` and `AWS::Region`
rather than templating them in yourself.

```yaml
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          ACCOUNT_ID: !Ref AWS::AccountId
          REGION: !Ref AWS::Region
```

### CDK

Prefer the resolved values off the stack — `Stack.of(this).account` / `Stack.of(this).region` — rather than reading from
environment variables. For unresolved tokens (equivalent to the CloudFormation pseudo parameters) use `Aws.ACCOUNT_ID`
and `Aws.REGION`.

```ts
import { Aws, Stack } from 'aws-cdk-lib';

// Resolved at synth time (when env is set on the stack)
const accountId = Stack.of(this).account;
const region = Stack.of(this).region;

// Unresolved tokens — resolved by CloudFormation at deploy time
const accountToken = Aws.ACCOUNT_ID;
const regionToken = Aws.REGION;
```

### Terraform

When writing Terraform code, rather than using variables to get the current AWS account ID / AWS region you should use
`data`/`locals` to set them for the entire project once, reliably.

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.id
}
```
