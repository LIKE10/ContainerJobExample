# Stage 1 – Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/ContainerJob/ContainerJob.csproj ./ContainerJob/
RUN dotnet restore ./ContainerJob/ContainerJob.csproj

COPY src/ContainerJob/ ./ContainerJob/
RUN dotnet publish ./ContainerJob/ContainerJob.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# Stage 2 – Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ContainerJob.dll"]
