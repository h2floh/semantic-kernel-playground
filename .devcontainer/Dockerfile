# Dockerfile
FROM mcr.microsoft.com/devcontainers/base:jammy

# Install any additional dependencies here
RUN apt-get update && \
	apt-get install -y curl apt-transport-https lsb-release gnupg && \
	curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null && \
	AZ_REPO=$(lsb_release -cs) && \
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
	apt-get update && \
	apt-get install -y azure-cli && \
	apt-get install -y dotnet-sdk-8.0 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /workspace