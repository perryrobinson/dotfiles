# Docker and WSL Steering

- This machine is WSL on Windows. Docker is expected to be provided by Docker Desktop on the Windows side.
- If Docker is unavailable from WSL, check whether Docker Desktop is running before concluding Docker is not installed.
- The tested WSL command to start Docker Desktop is `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"`.
- After starting Docker Desktop, poll with `docker ps` until the daemon is ready.
- If Codex sandboxing reports permission denied on `/var/run/docker.sock`, retry the Docker command with escalated permissions.
- If the WSL `docker` command is missing or broken, the tested Windows Docker CLI path is `/mnt/c/Program Files/Docker/Docker/resources/bin/docker.exe`.
- Docker Compose is also available from Windows at `/mnt/c/Program Files/Docker/Docker/resources/bin/docker-compose.exe`.
- Do not install Docker directly inside WSL unless explicitly asked. Some people use that setup, but this machine's default is Windows Docker Desktop with WSL integration.
