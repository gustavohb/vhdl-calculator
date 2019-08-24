# Calculadora em VHDL

Projeto de uma calculadora simples em VHDL utilizando máquina de estados.

## Equipamentos Utilizados no Projeto

* Placa Altera DE1 (Cyclone II: EP2C20F484C7)

* Teclado PS2

## Software Utilizado no Projeto

* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition

## Funcionalidades

* Operações aritméticas básicas (adição, subtração, multiplicação e divisão).

* Capacidade de usar o último resultado como operando da próxima operação.

* Capacidade de realizar operações com operandos de até 13 bits.

* Capacidade de operar com inteiros positivos e negativos no formato de complemento de 2.

* Indicação de *overflow*.

* Apresentação dos resultados nos quatro displays de 7 segmentos da placa.

* Controle de brilho dos *displays* de 7 segmentos usando os *switches* da placa SW[7 ~ 0].

* Entrada de dados utilizando um teclado com interface PS2.


## Organização do Projeto

O projeto é estruturado em torno do arquivo principal `calculator.vhd`, que contém a descrição da máquina de estados que é o cerne deste trabalho.


### Máquina de Estados

A máquina de estados utilizada neste projeto é baseada na máquina de estados descrita por [Robert M. Vunabandi](https://github.com/robertvunabandi/CalcFSM) e é apresentada de forma geral na figura abaixo.

![fsm](https://user-images.githubusercontent.com/3193712/63642682-44518580-c699-11e9-9acb-c7a60ad24716.png)

Existem três operandos de interesse: o primeiro, o segundo e o subsequente, denominados no
código como `first_number`, `second_number` e `trailing_number`, respectivamente. Os dois primeiros definem as operações convencionais e o terceiro é utilizado como uma variável auxiliar para operações sequenciais.

Os estados são descritos por:

* `INITIAL`: Estado inicial, com resultado zero. Obtido no início da execução ou com o uso do `RESET`;

* `TRANSITION FROM INITIAL`:  Estado que identifica a entrada do primeiro operando;

* `TRANSITION`: Estado que identifica que o primeiro operando foi definido e determina a entrada da operação;

* `TRANSITION FROM TRANSITION`: Identifica a entrada do segundo operando, após a definição da operação;

* `EQUAL`: Após a inserção do segundo operando, exibe o resultado da operação, caso o mesma seja válida;

* `TRAILING`: Caso onde são feitas operações sequenciais, lê-se um operador para a próxima operação sobre o resultado atual;

* `TRANSITION FROM TRAILING`: Ainda no caso de operações sequenciais, lê o número subsequente, que se torna o segundo operando, enquanto que o primeiro operando é o resultado da operação anterior;

* `ERROR`: Estado de erro, quando algum resultado inválido é obtido (fora do intervalo pré-determinado ou divisão por zero).

Além da definição dos estados e transições, o arquivo principal também estrutura a interação entre as bibliotecas genéricas (`general`), de entrada e saída (`io`) e numérica (`numeric`). Os arquivos que constituem cada uma destas bibliotecas estão dentro do diretório `/lib/`.


### Biblioteca genérica (*general.vhd*)

A biblioteca genérica é composta pelos seguintes arquivos:

* `binary_to_bcd.vhd`: realiza a conversão de um valor binário de 13 *bits* (em complemento de 2) para codificação binária decimal (BCD) de 16 *bits* utilizando o algoritmo *double dabble*;

* `conv_7seg.vhd`: converte um valor binário de 4 *bits* referente à um dígito de 0 à 9, sinal negativo ou valor nulo, para o *display* de sete segmentos;

* `pwm.vhd`: define o controlador PWM para o controle de brilho dos *displays* de sete segmentos;

* `scancode_to_calc_input.vhd`: realiza a conversão de uma entrada do teclado PS2 para um vetor de 5 *bits* representando um dígito, uma operação aritmética, o comando *ENTER* ou o comando *CLEAR*.


### Biblioteca de I/O (*io.vhd*)

A biblioteca de entrada e saída é composta pelos seguintes arquivos:

* `io.vhd`: define o pacote com os demais arquivos da biblioteca de entrada e saída;

* `kbdex_ctrl.vhd`:  define o controlador para o teclado PS2, permitindo a leitura do código referente à um conjunto de até três teclas, totalizando 48 *bits*;

* `ps2_iobase.vhd`: realiza a comunicação com o teclado através da porta PS2.


### Biblioteca numérica (*numeric.vhd*)

A biblioteca numérica contém um único arquivo, `numeric.vhd`, que define o pacote contendo todas as operações aritméticas, bem como os algoritmos que as implementam.

O pacote com as operações aritméticas contém as funções:

* `bit_adder_subtractor()`: Realiza as operações de soma e subtração com apenas um *bit*. É o algoritmo de um somador completo;

* `ripple_adder_subtractor()`: Realiza as operações de soma e subtração com vetores de *bits*. Este algoritmo implementa a estrutura de um somador completo de múltiplos *bits*, que é o encadeamento de somadores completos de um *bit* em cascata, onde o *carry-out* de um é alimentado ao *carry-in* do seguinte (mais significativo);

* `booth_multiplier()`: Implementa um multiplicador baseado no algoritmo de Booth para vetores de *bits* representando números em complemento de dois;

* `divide()`: Utiliza o método de divisão do pacote `IEEE.NUMERIC_STD`.

## Limitações

* Há a limitação de representação com 13 bits, de modo que os valores inseridos e/ou resultados obtidos devem estar contidos no intervalo [-4096, 4095];

* Os valores podem ser representados com os quatro displays, mas o sinal negativo para números com quatro dígitos precisou ser representado exclusivamente através de um LED auxiliar (LEDR9);

* Todos os valores de entrada e resultados são inteiros, não foi implementado ponto fixo ou flutuante;

* Muito embora todas as operações aritméticas básicas tenham sido implementadas, a divisão é inteira, e o resto é desconsiderado, isto é, o resultado da divisão entre dois operandos a, b ∈ Z é dado por a ÷ b = ⌊a/b⌋.


## Autores

* [Gustavo H. Barrionuevo](https://github.com/gustavohb)
* [Nilton Gomes Martins Junior](https://github.com/NiltonGMJunior)


## Agradecimentos

Agradecemos ao professor Rodrigo M. Bacurau pela total ajuda no desenvolvimento deste projeto.

Agradecemos também a:
* Thiago Borges Abdnur pelo controlador de teclado PS2;
* [Robert M. Vunabndi](https://github.com/robertvunabandi/CalcFSM) pela lógica da máquina de estados.


## Licença

Consulte o arquivo [LICENSE](https://github.com/gustavohb/calculator/blob/master/LICENSE) para obter os direitos e limitações da licença (MIT)
