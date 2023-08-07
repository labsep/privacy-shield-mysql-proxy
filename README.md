# Privacy Shield MySQL Proxy

## Instalação

## Iniciando o proxy

Em um terminal, iniciar um servidor MySQL conectando-se na porta 4040.

mysql -u root -h -p -P 4040

Em outro terminal, iniciar o mysql-proxy apontando o caminho até main.lua.

mysql-proxy --proxy-lua-script=C:\...\privacy-shield\src\main.lua

