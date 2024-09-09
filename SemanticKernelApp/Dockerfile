# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8 AS build
WORKDIR /app

# Copy and restore dependencies
COPY ./*.csproj ./
RUN dotnet restore

# Copy the rest of the source code and build
COPY . ./
RUN dotnet publish -c Release -o out

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8 AS runtime
WORKDIR /app
COPY --from=build /app/out ./

# Start the application
ENTRYPOINT ["dotnet", "SemanticKernelApp.dll"]