# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy everything
COPY . .

# Restore dependencies using the csproj in root
RUN dotnet restore "hello-world-api.csproj"

# Publish
RUN dotnet publish "hello-world-api.csproj" -c Release -o /out

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app

COPY --from=build /out .

EXPOSE 80

ENTRYPOINT ["dotnet", "hello-world-api.dll"]

