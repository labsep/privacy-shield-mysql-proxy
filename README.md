# Privacy Shield MySQL Proxy

## Dependências

Você precisa de duas dependências:
* MySQL
* [Lua versão 5.1.X](https://luabinaries.sourceforge.net/download.html)
* [MySQL Proxy versão 0.8.5](https://downloads.mysql.com/archives/proxy/?os=src)

## Iniciando o Proxy

Em um terminal, inicie o MySQL Proxy passando como parâmetro o caminho absoluto do arquivo Lua:

```mysql-proxy --proxy-lua-script="C:\...\privacy_shield\dist\main.lua```

Em outro terminal, inicie um cliente MySQL na porta 4040:

```mysql -u root -p -h 127.0.0.1 -P 4040```

# Guia de Desenvolvimento

## Organização

A estrutura do código é organizada de forma que cada comando MySQL possui o seu próprio arquivo, que deve (na maioria dos casos) conter as seguintes funções:
* Uma função que recebe a query SQL e retorna uma table contendo os dados dessa query;
* Uma função que encripta ou decripta os dados da query contidos nessa table;
* Uma função que compila os dados já encriptados ou decriptados de volta para uma query SQL contendo essas mudanças;
* Uma função que chama as três funções anteriores, embrulhando todo o processo em apenas uma função.
