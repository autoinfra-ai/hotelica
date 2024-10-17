git checkout master && git fetch upstream && git rebase upstream/master

For Searxng changes to support json
# Authenticate with ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 406515214055.dkr.ecr.us-east-2.amazonaws.com

# Build and push directly to ECR
docker buildx build --platform linux/arm64 -t 406515214055.dkr.ecr.us-east-2.amazonaws.com/searxng-hotelica:arm64 --push .