# Stage 1 – Build
FROM mcr.microsoft.com/dotnet/sdk:10.0-azurelinux3.0 AS build
WORKDIR /src

COPY src/ScheduledExample/ScheduledExample.csproj src/ScheduledExample/
RUN dotnet restore src/ScheduledExample/ScheduledExample.csproj

COPY src/ScheduledExample/. src/ScheduledExample/
RUN dotnet publish src/ScheduledExample/ScheduledExample.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# Stage 2 – Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0-azurelinux3.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ScheduledExample.dll"]
