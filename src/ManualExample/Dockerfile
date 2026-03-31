# Stage 1 – Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ManualExample.csproj .
RUN dotnet restore ManualExample.csproj

COPY . .
RUN dotnet publish ManualExample.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# Stage 2 – Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ManualExample.dll"]
