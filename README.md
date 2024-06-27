# Teste de balança Ip Toledo 9091  

## Descrição

Este projeto tem como objetivo realizar a comunicação com a balança Toledo 9091, através de um servidor TCP/IP, e realizar a leitura do peso. Para a comunicação com a balança, foi utilizado o conversor RS232/TCP/IP da marca Comm5, modelo 4s-tcp-2. 

## Dificuldades

A balança Toledo 9091 utilizada para teste, não possui a possibilidade de enviar os dados 
em 8bits, o que dificultou a comunicação. Para solucionar este problema, foi necessário realizar uma conversão dos dados recebidos, de 7bits para 8bits, antes de realizar o 
tratamento dos dados.

## Dependências

Não há dependências adicionais para a execução deste projeto.

## Execução

Para executar o projeto, basta rodar o comando 
  ```bash
    flutter run
  ```

## Observações

Este projeto foi desenvolvido apenas para fins de teste. Espero que este código possa ajudar alguém que esteja passando por dificuldades semelhantes.