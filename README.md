# Notes-API

A simple serverless REST API for note-taking, built using AWS Lambda, API Gateway, and DynamoDB, and provisioned via Terraform.

## Features

- **Create Notes**: Add new notes via a POST endpoint.
- **Retrieve Notes**: Fetch individual notes via a GET endpoint.
- **Serverless Architecture**: No server management—leverages AWS Lambda and DynamoDB.
- **Infrastructure as Code**: All AWS resources are defined and managed through Terraform.
- **Local Development Friendly**: Can be run and tested locally using [LocalStack](https://github.com/localstack/localstack).

## Architecture

- **API Gateway**: Exposes REST endpoints `/notes` (POST) and `/notes/{noteId}` (GET).
- **AWS Lambda**: Handles the business logic for note creation and retrieval.
- **DynamoDB**: Stores notes, with `noteId` as the primary key.
- **IAM Roles & Policies**: Secure least-privilege access for Lambda to DynamoDB and CloudWatch Logs.

## Endpoints

- `POST /notes`  
  Create a new note.  
  **Body**: JSON describing the note.

- `GET /notes/{noteId}`  
  Retrieve a note by its ID.

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.2.0
- [AWS CLI](https://aws.amazon.com/cli/) or [LocalStack](https://github.com/localstack/localstack) for local development
- Python 3.9+ (for Lambda function)

### Deployment

1. **Clone the repository**
   ```sh
   git clone https://github.com/Samrhan/Notes-API.git
   cd Notes-API/terraform
   ```

2. **Configure AWS credentials**  
   For local development, you can use dummy credentials as shown in `main.tf`.

3. **Initialize and apply Terraform**
   ```sh
   terraform init
   terraform apply
   ```

4. **Find your API endpoint**  
   After deployment, Terraform will output the base URL (`api_endpoint_url`).

### Lambda Function

- The Lambda code is in `terraform/lambda.py`.
- It routes requests based on HTTP method and path.
- Handles CORS for local development (see `Access-Control-Allow-Origin` in responses).

### Environment Variables

- `DYNAMODB_TABLE_NAME` (automatically set by Terraform)

## Customization

- To add more features (update/delete notes), expand the Lambda handler and permissions in Terraform.
- For production, restrict CORS and use secure AWS credentials.

## Outputs

- **api_endpoint_url**: The base URL to access your deployed API.

## License

MIT

---

*This project is for educational and demonstration purposes.*