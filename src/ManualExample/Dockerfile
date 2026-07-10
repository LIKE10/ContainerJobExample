# Stage 1 – Build
FROM mcr.microsoft.com/dotnet/sdk:10.0-azurelinux3.0 AS build
WORKDIR /src

COPY src/ManualExample/ManualExample.csproj src/ManualExample/
RUN dotnet restore src/ManualExample/ManualExample.csproj

COPY src/ManualExample/. src/ManualExample/
RUN dotnet publish src/ManualExample/ManualExample.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# Stage 2 – Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0-azurelinux3.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ManualExample.dll"]
