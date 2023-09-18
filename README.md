# Privacy Shield MySQL Proxy

Este projeto é um proxy que busca facilitar a adesão de pequenos negócios que utilizem MySQL como tecnologia de banco de dados à LGPD (Lei Geral de Proteção de Dados). O projeto busca permitir a encriptação/decriptação da comunicação com o banco de dados de forma rápida e fácil por meio de uma arquitetura *plug and play*.

## Dependências

Você precisa de três dependências:
* MySQL
* [Lua versão 5.1.X](https://luabinaries.sourceforge.net/download.html)
* [MySQL Proxy versão 0.8.5](https://downloads.mysql.com/archives/proxy/?os=src)

## Rodando o Proxy

Em um terminal, inicie o MySQL Proxy passando como parâmetro o caminho absoluto do arquivo Lua:

```mysql-proxy --proxy-lua-script="C:\...\privacy_shield\dist\main.lua```

Em outro terminal, inicie um cliente MySQL na porta 4040:

```mysql -u root -p -h 127.0.0.1 -P 4040```

Agora qualquer operação realizada pelo cliente MySQL passará pelo MySQL Proxy.

## Um Exemplo

### Configuração

No estado atual de desenvolvimento, o proxy ainda não encripta automaticamente o banco de dados e não armazena a configuração do banco de dados em um arquivo separado. Por enquanto, precisamos criar o nosso banco de dados com os tipos apropriados para os campos (utilizando o tipo VARBINARY):

```sql
CREATE TABLE pacientes (
  nome VARBINARY(255) NOT NULL,
  cpf VARBINARY(255) NOT NULL,
  idade VARBINARY(255) NOT NULL,
  data_nascimento VARBINARY(255) NOT NULL
);
```

Por enquanto, também devemos armazenar a estrutura do banco de dados na váriavel `DATABASE_CONFIGURATION` em `dist/main.lua`.

```lua
local DATABASE_CONFIGURATION = {
    name = "teste",
    tables = {
        {
            name = "pacientes",
            columns = {
                {
                    name = "nome",
                    type = "VARCHAR(255)",
                    encrypt = true
                },
                {
                    name = "cpf",
                    type = "CHAR(11)",
                    encrypt = true
                },
                {
                    name = "idade",
                    type = "INT",
                    encrypt = true
                },
                {
                    name = "data_nascimento",
                    type = "DATE",
                    encrypt = true
                }
            }
        }
    }
}
```

Seguindo o desenvolvimento do proxy, toda essa configuração será automatizada e facilitada por meio de uma interface gráfica.

### Uma operação básica no banco de dados

Vamos inserir um novo paciente no banco de dados:

```sql
INSERT INTO pacientes (nome, cpf, idade, data_nascimento)
VALUES (
  'Fulano de Tal',
  '123.321.456-77',
  18,
  '2005-09-10'
);
```

E então buscar esse paciente:

```sql
SELECT * FROM pacientes WHERE nome = 'Fulano de Tal';
```

```
+-----------------+-----------------+-----------------+-----------------+
| nome            | cpf             | idade           | data_nascimento |
+-----------------+-----------------+-----------------+-----------------+
| Fulano de Tal   | 123.321.456     | 18              | 2005-09-10      |
+-----------------+-----------------+-----------------+-----------------+
```

Os dados foram retornados já decriptografados. O cliente não precisou alterar a sua query de forma alguma. No entato, se olharmos os dados armazenados no banco de dados, perceberemos que eles estão criptografados:

```
+---------------------+---------------------+---------------------+---------------------+
| nome                | cpf                 | idade               | data_nascimento     |
+---------------------+---------------------+---------------------+---------------------+
| FQ    ◄ñ²·äþk@3Ôk█= | ƒ%*©ÿ.♥Í±‼Æ:øÞ       | 4█£Q↔Ôá█êƒa©⌂^ ø    | ▬═Óp↕ä¡\    ÈÔLEÄé▀ |
+---------------------+---------------------+---------------------+---------------------+
```

# Guia de Desenvolvimento

## Fluxo

![darkmode](https://github.com/labsep/privacy-shield-mysql-proxy/assets/141641281/bd71de27-7dc7-46e8-9e69-fcede710624a#gh-dark-mode-only)

O fluxo do programa acontece na seguinte sequência:

1. O programa lê um arquivo de configuração JSON que contêm informações sobre a estrutura do banco de dados e quais campos devem ser criptografados.

   Essa etapa ainda não está implementada no código. Essa configuração está salva, por enquanto, na váriavel `DATABASE_CONFIGURATION` em `main.lua`;

3. O proxy intercepta pacotes enviados ao servidor MySQL;

4. O programa avalia se o pacote é uma query. Se não, o pacote é enviado ao servidor MySQL sem nenhuma modificação;

5. Em seguida, o programa extrai os dados da query, transformando-a em uma `table` Lua para facilitar a sua modificação;

6. Baseado na configuração do usuário e no tipo de query, o programa criptografa ou decriptografa os dados;

7. O programa reconstrói a query MySQL utilizando os dados criptografados/decriptografados;

8. O proxy envia o pacote contendo a query modificada para o servidor MySQL.

## Organização

A estrutura do código é organizada de forma que cada comando MySQL possui o seu próprio arquivo, que deve (na maioria dos casos) conter as seguintes funções:

* Uma função que recebe a query SQL e retorna uma table contendo os dados dessa query;
  
* Uma função que encripta ou decripta os dados da query contidos nessa table;
  
* Uma função que compila os dados já encriptados ou decriptados de volta para uma query SQL contendo essas mudanças;
  
* Uma função que chama as três funções anteriores, embrulhando todo o processo em apenas uma função.
