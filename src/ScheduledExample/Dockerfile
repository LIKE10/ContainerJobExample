# Stage 1 – Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ScheduledExample.csproj .
RUN dotnet restore ScheduledExample.csproj

COPY . .
RUN dotnet publish ScheduledExample.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# Stage 2 – Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ScheduledExample.dll"]
