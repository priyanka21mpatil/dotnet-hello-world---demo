# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy everything
COPY . .

# Change directory into your actual project folder
WORKDIR /src/hello-world-api

RUN dotnet restore
RUN dotnet publish -c Release -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app

COPY --from=build /app .

EXPOSE 80

ENTRYPOINT ["dotnet", "hello-world-api.dll"]

