@echo off

echo Docker login, Make sure to use an account with access to the PHederation docker hub images.
docker login

IF %ERRORLEVEL% EQU 0 (
    goto honeur_setup
) else (
    echo Failed to Login
    goto eof
)

:honeur_setup
echo Press [Enter] to start removing the existing PHederation containers
pause>NUL

echo Stop and Remove previous PHederation containers.
PowerShell -Command "docker stop $(docker ps --filter 'network=honeur-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter 'network=honeur-net' -q -a)" >nul 2>&1

echo Removing shared volume
docker volume rm shared >nul 2>&1

echo Success
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -fsSL https://github.com/solventrix/Honeur-Setup/releases/download/v1.5/docker-compose-phederation-standard.yml --output docker-compose.yml

set /p honeur_host_machine="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET honeur_host_machine=localhost
set /p honeur_zeppelin_logs="Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: " || SET honeur_zeppelin_logs=./zeppelin/logs
set /p honeur_zeppelin_notebooks="Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: " || SET honeur_zeppelin_notebooks=./zeppelin/notebook
set /p honeur_analytics_organization="Enter your PHederation organization [Janssen]: " || SET honeur_analytics_organization=Janssen
set /p honeur_analytics_shared_folder="Enter the directory where Zeppelin will save the prepared distributed analytics data [./distributed-analytics]: " || SET honeur_analytics_shared_folder=./distributed-analytics

PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_BACKEND_HOST','%honeur_host_machine%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ZEPPELIN_LOGS','%honeur_zeppelin_logs%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ZEPPELIN_NOTEBOOKS','%honeur_zeppelin_notebooks%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ANALYTICS_ORGANIZATION','%honeur_analytics_organization%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_DISTRIBUTED_ANALYTICS_SHARED','%honeur_analytics_shared_folder%') | Set-Content docker-compose.yml"

docker volume create --name pgdata
docker volume create --name shared

echo set COMPOSE_HTTP_TIMEOUT=3000
set COMPOSE_HTTP_TIMEOUT=3000

docker-compose pull
docker-compose up -d

echo Removing downloaded files
del docker-compose.yml

echo postgresql is available on %honeur_host_machine%:5444
echo webapi/atlas is available on http://%honeur_host_machine%:8080/webapi and http://%honeur_host_machine%:8080/atlas respectively
echo Zeppelin is available on http://%honeur_host_machine%:8082
echo Zeppelin Spark Master URL is available on spark://%honeur_host_machine%:7077
echo Zeppelin logs are available in directory %honeur_zeppelin_logs%
echo Zeppelin notebooks are available in directory %honeur_zeppelin_notebooks%
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL