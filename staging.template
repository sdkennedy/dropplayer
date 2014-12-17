{
    "Parameters": {
        "OperatorEmail": {
            "Description": "Email address to notify if there are any operational issues",
            "Type": "String",
            "AllowedPattern": "([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)",
            "ConstraintDescription": "must be a valid email address."
        }
    },
    "Mappings": {
        "Region2Principal": {
            "us-east-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "us-west-2": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "us-west-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "eu-west-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "ap-southeast-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "ap-northeast-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "ap-southeast-2": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "sa-east-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            },
            "cn-north-1": {
                "EC2Principal": "ec2.amazonaws.com.cn",
                "OpsWorksPrincipal": "opsworks.amazonaws.com.cn"
            },
            "eu-central-1": {
                "EC2Principal": "ec2.amazonaws.com",
                "OpsWorksPrincipal": "opsworks.amazonaws.com"
            }
        }
    },
    "Resources": {
        "WorkerQueue" : {
            "Type" : "AWS::SQS::Queue"
        },
        "ServicesTable":{
            "Type": "AWS::DynamoDB::Table",
            "Properties":{
                "AttributeDefinitions":[
                    {
                        "AttributeName":"serviceId",
                        "AttributeType":"S"
                    }
                ],
                "KeySchema":[
                    {
                        "AttributeName":"serviceId",
                        "KeyType":"HASH"
                    }
                ],
                "ProvisionedThroughput":{
                    "ReadCapacityUnits":1,
                    "WriteCapacityUnits":1
                }
            }
        },
        "SongsTable":{
            "Type": "AWS::DynamoDB::Table",
            "Properties":{
                "AttributeDefinitions":[
                    {
                        "AttributeName":"userId",
                        "AttributeType":"S"
                    },
                    {
                        "AttributeName":"songId",
                        "AttributeType":"S"
                    }
                ],
                "KeySchema":[
                    {
                        "AttributeName":"userId",
                        "KeyType":"HASH"
                    },
                    {
                        "AttributeName":"songId",
                        "KeyType":"RANGE"
                    }
                ],
                "ProvisionedThroughput":{
                    "ReadCapacityUnits":1,
                    "WriteCapacityUnits":1
                }
            }
        },
        "UsersTable":{
            "Type": "AWS::DynamoDB::Table",
            "Properties":{
                "AttributeDefinitions":[
                    {
                        "AttributeName":"userId",
                        "AttributeType":"S"
                    }
                ],
                "KeySchema":[
                    {
                        "AttributeName":"userId",
                        "KeyType":"HASH"
                    }
                ],
                "ProvisionedThroughput":{
                    "ReadCapacityUnits":1,
                    "WriteCapacityUnits":1
                }
            }
        },
        "WebServerRole": {
            "Type": "AWS::IAM::Role",
            "Properties": {
                "AssumeRolePolicyDocument": {
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "Service": [
                                    {
                                        "Fn::FindInMap": [
                                            "Region2Principal",
                                            {"Ref": "AWS::Region"},
                                            "EC2Principal"
                                        ]
                                    }
                                ]
                            },
                            "Action": [
                                "sts:AssumeRole"
                            ]
                        }
                    ]
                },
                "Path": "/"
            }
        },
        "WebServerRolePolicy": {
            "Type": "AWS::IAM::Policy",
            "Properties": {
                "PolicyName": "WebServerRole",
                "PolicyDocument": {
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "NotAction": "iam:*",
                            "Resource": "*"
                        },
                        {
                          "Effect": "Allow",
                          "Action": "s3:PutObject",
                          "Resource": "arn:aws:s3:::elasticbeanstalk-us-west-2-711231113371/resources/environments/logs/*"
                        },
                        {
                          "Effect": "Allow",
                          "Action": "kinesis:PutRecord*",
                          "Resource": "arn:aws:kinesis:us-west-2:711231113371:stream/drop_worker"
                        },
                        {
                           "Effect": "Allow",
                           "Action": "dynamodb:*",
                           "Resource": "*"
                        }
                    ]
                },
                "Roles": [
                    {
                        "Ref": "WebServerRole"
                    }
                ]
            }
        },
        "WebServerInstanceProfile": {
            "Type": "AWS::IAM::InstanceProfile",
            "Properties": {
                "Path": "/",
                "Roles": [ { "Ref": "WebServerRole" } ]
            }
        },
        "DropplayerApplication": {
            "Type": "AWS::ElasticBeanstalk::Application",
            "Properties": {
                "Description": "Dropplayer Application"
            }
        },
        "DropplayerApplicationLatestVersion": {
            "Type": "AWS::ElasticBeanstalk::ApplicationVersion",
            "Properties": {
                "Description": "Latest Version",
                "ApplicationName": { "Ref": "DropplayerApplication" },
                "SourceBundle": {
                    "S3Bucket": "dropplayer-code",
                    "S3Key": "dropplayer-2014-12-15-1617.zip"
                }
            }
        },
        "DropplayerWebConfigurationTemplate": {
            "Type": "AWS::ElasticBeanstalk::ConfigurationTemplate",
            "Properties": {
                "ApplicationName": { "Ref": "DropplayerApplication" },
                "Description": "Default Web Worker Configuration",
                "SolutionStackName": "64bit Amazon Linux 2014.09 v1.0.9 running Node.js",
                "OptionSettings": [
                    {
                        "Namespace": "aws:elasticbeanstalk:container:nodejs",
                        "OptionName": "NodeCommand",
                        "Value": "node ./dist/src/main.js api"
                    },
                    {
                        "Namespace": "aws:elb:loadbalancer",
                        "OptionName": "LoadBalancerHTTPSPort",
                        "Value": 443
                    },
                    {
                        "Namespace": "aws:elb:loadbalancer",
                        "OptionName": "SSLCertificateId",
                        "Value": "arn:aws:iam::711231113371:server-certificate/dropplayer"
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "IamInstanceProfile",
                        "Value": { "Ref":"WebServerInstanceProfile" }
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "EC2KeyName",
                        "Value": "drop"
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "InstanceType",
                        "Value": "t1.micro"
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "NODE_ENV",
                        "Value": "staging"
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_AWS_REGION",
                        "Value": { "Ref" : "AWS::Region" }
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_SERVICES",
                        "Value": {"Ref" : "ServicesTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_USERS",
                        "Value": {"Ref" : "UsersTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_SQS_WORKER_QUEUE",
                        "Value": {"Ref": "WorkerQueue"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_SONGS",
                        "Value": {"Ref" : "SongsTable"}
                    }
                ]
            }
        },
        "DropplayerWebEnvironment": {
            "Type": "AWS::ElasticBeanstalk::Environment",
            "Properties": {
                "EnvironmentName":"DropplayerWeb",
                "Description": "AWS Elastic Beanstalk Environment running Dropplayer Web",
                "ApplicationName": { "Ref": "DropplayerApplication" },
                "TemplateName": { "Ref": "DropplayerWebConfigurationTemplate" },
                "VersionLabel": { "Ref": "DropplayerApplicationLatestVersion" }
            }
        },
        "DropplayerWorkerConfigurationTemplate": {
            "Type": "AWS::ElasticBeanstalk::ConfigurationTemplate",
            "Properties": {
                "ApplicationName": { "Ref": "DropplayerApplication" },
                "Description": "Default Dropplayer Worker Configuration",
                "SolutionStackName": "64bit Amazon Linux 2014.09 v1.0.9 running Node.js",
                "OptionSettings": [
                    {
                        "Namespace": "aws:elasticbeanstalk:container:nodejs",
                        "OptionName": "NodeCommand",
                        "Value": "node ./dist/src/main.js worker"
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "IamInstanceProfile",
                        "Value": { "Ref":"WebServerInstanceProfile" }
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "EC2KeyName",
                        "Value": "drop"
                    },
                    {
                        "Namespace": "aws:autoscaling:launchconfiguration",
                        "OptionName": "InstanceType",
                        "Value": "m1.small"
                    },
                    {
                        "Namespace": "aws:autoscaling:asg",
                        "OptionName": "MinSize",
                        "Value": 2
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "NODE_ENV",
                        "Value": "staging"
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_AWS_REGION",
                        "Value": { "Ref" : "AWS::Region" }
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_SERVICES",
                        "Value": {"Ref" : "ServicesTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_USERS",
                        "Value": {"Ref" : "UsersTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_SONGS",
                        "Value": {"Ref" : "SongsTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_DYNAMODB_TABLE_SONGS",
                        "Value": {"Ref" : "SongsTable"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:application:environment",
                        "OptionName": "DROP_SQS_WORKER_QUEUE",
                        "Value": {"Ref": "WorkerQueue"}
                    },
                    {
                        "Namespace": "aws:elasticbeanstalk:sqsd",
                        "OptionName": "WorkerQueueURL",
                        "Value": {"Ref": "WorkerQueue"}
                    }
                ]
            }
        },
        "DropplayerWorkerEnvironment": {
            "Type": "AWS::ElasticBeanstalk::Environment",
            "Properties": {
                "EnvironmentName":"DropplayerWorker",
                "Description": "AWS Elastic Beanstalk Environment running Dropplayer Web",
                "ApplicationName": { "Ref": "DropplayerApplication" },
                "TemplateName": { "Ref": "DropplayerWorkerConfigurationTemplate" },
                "VersionLabel": { "Ref": "DropplayerApplicationLatestVersion" },
                "Tier":{
                  "Type" : "SQS/HTTP",
                  "Name" : "Worker",
                  "Version" : "1.0"
                }
            }
        },
        "AlarmTopic": {
            "Type": "AWS::SNS::Topic",
            "Properties": {
                "Subscription": [
                    {
                        "Endpoint": { "Ref": "OperatorEmail" },
                        "Protocol": "email"
                    }
                ]
            }
        }
    },
    "Outputs": {
        "URL": {
            "Description": "URL of the AWS Elastic Beanstalk Environment",
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        "http://",
                        {
                            "Fn::GetAtt": [
                                "DropplayerWebEnvironment",
                                "EndpointURL"
                            ]
                        }
                    ]
                ]
            }
        }
    }
}